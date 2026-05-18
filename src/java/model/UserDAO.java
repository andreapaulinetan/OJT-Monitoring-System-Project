package model;

import java.sql.*;
import java.time.Year;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletContext;
import util.DBConnection;

public class UserDAO {

    /**
     * VALIDATE USER: Checks both Admin and Intern tables (DBMS 1 - Apache Derby).
     */
    public static User validateUser(String email, String plainPassword, ServletContext context) {
        String hashedPassword = util.CryptoUtil.hashPassword(plainPassword);
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return null;

            // 1. Check ADMIN Table
            String adminSql = "SELECT * FROM ADMIN WHERE LOWER(EMAIL) = ?";
            try (PreparedStatement ps = conn.prepareStatement(adminSql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String dbPass = rs.getString("PASSWORD");
                        if (dbPass != null && (dbPass.equals(hashedPassword) || dbPass.equals(plainPassword))) {
                            return mapResultSetToUser(rs, "Admin", context);
                        }
                    }
                }
            }

            // 2. Check INTERN Table
            String internSql = "SELECT * FROM INTERN WHERE LOWER(EMAIL) = ?";
            try (PreparedStatement ps = conn.prepareStatement(internSql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String dbPass = rs.getString("PASSWORD");
                        if (dbPass != null && (dbPass.equals(hashedPassword) || dbPass.equals(plainPassword))) {
                            return mapResultSetToUser(rs, rs.getString("ROLE"), context);
                        }
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * GET ALL INTERNS: Fetches all interns (DBMS 1 - Apache Derby).
     */
    public static List<User> getAllInterns(ServletContext context) {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM INTERN";
        
        try (Connection conn = DBConnection.getDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                User u = mapResultSetToUser(rs, rs.getString("ROLE"), context);
                list.add(u);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * GET ALL SUBMISSIONS: Cross-Database Join (MySQL Data mapped with Derby User profiles).
     */
    public static List<ActivitySubmission> getAllSubmissions(ServletContext context) {
        List<ActivitySubmission> list = new ArrayList<>();
        
        // Load all Derby interns into a memory hash map to prevent an O(N) nested loop query disaster
        List<User> interns = getAllInterns(context);
        Map<String, User> internMap = new HashMap<>();
        for (User u : interns) {
            internMap.put(u.getId(), u);
        }

        String sql = "SELECT * FROM ACTIVITY_SUBMISSIONS";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                ActivitySubmission sub = new ActivitySubmission();
                String userId = rs.getString("USER_ID");
                
                sub.setSubmissionId(rs.getString("SUBMISSION_ID"));
                sub.setUserId(userId);
                sub.setDateSubmitted(rs.getDate("DATE_SUBMITTED"));
                sub.setDescription(rs.getString("DESCRIPTION"));
                sub.setSupportingFile(rs.getString("SUPPORTING_FILE"));
                sub.setOriginalFileName(rs.getString("ORIGINAL_FILE_NAME"));
                sub.setStatus(rs.getString("STATUS"));

                // Map cross-database reference data dynamically
                User profile = internMap.get(userId);
                if (profile != null) {
                    sub.setInternName(profile.getFullName());
                    sub.setAssignedOffice(profile.getOffice());
                } else {
                    sub.setInternName("System Admin Profile");
                    sub.setAssignedOffice("Main Administration Office");
                }
                list.add(sub);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * GET INDIVIDUAL STATUS: Fetches status from the separate MySQL monitoring database.
     */
    public static String getIndividualStatus(String userId, ServletContext context) {
        String status = "Pending"; 
        
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context)) {
            if (conn == null) {
                System.err.println("CRITICAL: MySQL connection failed inside getIndividualStatus!");
                return "Pending"; 
            }
            
            String sql = "SELECT STATUS FROM ACTIVITY_SUBMISSIONS WHERE USER_ID = ? ORDER BY DATE_SUBMITTED DESC LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        status = rs.getString("STATUS");
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error fetching status for User ID " + userId + ": " + e.getMessage());
            e.printStackTrace();
        }
        return status;
    }

    /**
     * GET PENDING LOGS COUNT: For dashboard statistics counters (DBMS 2 - MySQL).
     */
    public static int getPendingLogsCount(ServletContext context) {
        int count = 0;
        String query = "SELECT COUNT(*) FROM ACTIVITY_SUBMISSIONS WHERE STATUS = 'Pending'";

        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context)) {
            if (conn == null) {
                System.err.println("CRITICAL: MySQL connection failed inside getPendingLogsCount!");
                return 0;
            }

            try (PreparedStatement ps = conn.prepareStatement(query);
                  ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    count = rs.getInt(1);
                }
            }
        } catch (Exception e) {
            System.err.println("Error executing getPendingLogsCount query: " + e.getMessage());
            e.printStackTrace();
        }
        return count;
    }

    private static User mapResultSetToUser(ResultSet rs, String role, ServletContext context) throws SQLException {
        User u = new User();
        String id;
        try {
            id = rs.getString("INTERN_ID");
        } catch (SQLException e) {
            id = rs.getString("ADMIN_ID");
        }
        
        u.setId(id);
        u.setFirstName(rs.getString("FIRST_NAME"));
        u.setLastName(rs.getString("LAST_NAME"));
        u.setEmail(rs.getString("EMAIL"));
        u.setPassword(rs.getString("PASSWORD"));
        u.setRole(role); 
        
        try {
            u.setUniversity(rs.getString("UNIVERSITY"));
            u.setOffice(rs.getString("OFFICE"));
            u.setRoleCode(rs.getString("ROLE_CODE"));
            u.setCity(rs.getString("CITY"));
            
            if (!"Admin".equalsIgnoreCase(role)) {
                u.setLogStatus(getIndividualStatus(id, context));
            }
        } catch (SQLException e) {
            // Ignored for Admins
        }
        return u;
    }

    private static String generateCustomId(Connection conn, String prefix, String tableName, String idColumnName) throws SQLException {
        int currentYear = Year.now().getValue();
        String searchPattern, basePrefix;

        if (prefix.equals("INT")) {
            int companyAge = currentYear - 2020 + 1;
            searchPattern = prefix + currentYear + "-%"; 
            basePrefix = prefix + currentYear + "-" + companyAge;
        } else {
            searchPattern = prefix + currentYear + "-%";
            basePrefix = prefix + currentYear + "-";
        }

        String query = "SELECT MAX(" + idColumnName + ") AS LAST_ID FROM " + tableName + " WHERE " + idColumnName + " LIKE ?";
        
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, searchPattern);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getString("LAST_ID") != null) {
                    String lastId = rs.getString("LAST_ID");
                    String sequenceStr = lastId.substring(lastId.length() - 4);
                    int nextSequence = Integer.parseInt(sequenceStr) + 1;
                    return String.format("%s%04d", basePrefix, nextSequence);
                } else {
                    return basePrefix + "0001";
                }
            }
        }
    }

    public static boolean addIntern(User internUser, String birthMonth, int birthDate, int birthYear, int age, String contactNum, ServletContext context) {
        String sql = "INSERT INTO APP.INTERN (INTERN_ID, FIRST_NAME, MIDDLE_NAME, LAST_NAME, BIRTH_MONTH, BIRTH_DATE, BIRTH_YEAR, AGE, CITY, CONTACT_NUM, UNIVERSITY, ROLE, ROLE_CODE, OFFICE, EMAIL, PASSWORD) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return false;
            
            String generatedId = generateCustomId(conn, "INT", "INTERN", "INTERN_ID");
            internUser.setId(generatedId); // Sinasave ang generated ID sa object reference para mabasa ng servlet controllers
            
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, generatedId);
                ps.setString(2, internUser.getFirstName());
                ps.setString(3, internUser.getMiddleName());
                ps.setString(4, internUser.getLastName());
                ps.setString(5, birthMonth);
                ps.setInt(6, birthDate);
                ps.setInt(7, birthYear);
                ps.setInt(8, age);
                ps.setString(9, internUser.getCity());
                ps.setString(10, contactNum);
                ps.setString(11, internUser.getUniversity());
                ps.setString(12, internUser.getRole());
                ps.setString(13, internUser.getRoleCode());
                ps.setString(14, internUser.getOffice());
                ps.setString(15, internUser.getEmail());
                ps.setString(16, internUser.getPassword());
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public static boolean addAdmin(User adminUser, ServletContext context) {
        String sql = "INSERT INTO APP.ADMIN (ADMIN_ID, FIRST_NAME, MIDDLE_NAME, LAST_NAME, ROLE_CODE, EMAIL, PASSWORD) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return false;
            String generatedId = generateCustomId(conn, "ADM", "ADMIN", "ADMIN_ID");
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, generatedId);
                ps.setString(2, adminUser.getFirstName());
                ps.setString(3, adminUser.getMiddleName());
                ps.setString(4, adminUser.getLastName());
                ps.setString(5, "admin");
                ps.setString(6, adminUser.getEmail());
                ps.setString(7, adminUser.getPassword());
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}