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

    private static boolean passwordsMigrated = false;

    /**
     * VALIDATE USER: Fetches user by email from both Admin and Intern tables (DBMS 1 - Apache Derby).
     * Returns the User object (including stored password hash) so the caller can verify
     * the password via CryptoUtil.verifyPassword(). Returns null if no matching email found.
     */
    public static User findUserByEmail(String email, ServletContext context) {
        checkDerbySchema(context);
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return null;

            // 1. Check ADMIN Table
            String adminSql = "SELECT * FROM ADMIN WHERE EMAIL = ?";
            try (PreparedStatement ps = conn.prepareStatement(adminSql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return mapResultSetToUser(rs, "Admin", context);
                    }
                }
            }

            // 2. Check INTERN Table
            String internSql = "SELECT * FROM INTERN WHERE EMAIL = ?";
            try (PreparedStatement ps = conn.prepareStatement(internSql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return mapResultSetToUser(rs, rs.getString("ROLE"), context);
                    }
                }
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to look up user by email: " + email, e, null, context);
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
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to retrieve all intern profiles", e, null, context);
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
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context)) {
            if (conn == null) {
                System.err.println("CRITICAL: MySQL connection failed inside getAllSubmissions!");
                return list;
            }
            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    ActivitySubmission sub = new ActivitySubmission();
                    String userId = rs.getString("USER_ID");
                    
                    sub.setSubmissionId(rs.getString("SUBMISSION_ID"));
                    sub.setUserId(userId);
                    sub.setDateSubmitted(rs.getDate("DATE_SUBMITTED"));
                    sub.setDescription(rs.getString("DESCRIPTION"));
                    sub.setLearningReflection(rs.getString("LEARNING_REFLECTION"));
                    sub.setSupportingFile(rs.getString("SUPPORTING_FILE"));
                    sub.setOriginalFileName(rs.getString("ORIGINAL_FILE_NAME"));
                    sub.setStatus(rs.getString("STATUS"));

                    // Map cross-database reference data dynamically
                    String mappedId = mapToDerbyInternId(userId);
                    User profile = internMap.get(mappedId);
                    if (profile != null) {
                        sub.setInternName(profile.getFullName());
                        sub.setAssignedOffice(profile.getOffice());
                    } else {
                        sub.setInternName("System Admin Profile");
                        sub.setAssignedOffice("Main Administration Office");
                    }
                    list.add(sub);
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to fetch all activity submissions", e, null, context);
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
            
            String sql = "SELECT STATUS FROM ACTIVITY_SUBMISSIONS WHERE USER_ID = ? OR USER_ID LIKE ? ORDER BY DATE_SUBMITTED DESC LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, userId);
                
                String likePattern = "";
                try {
                    int seq = Integer.parseInt(userId);
                    likePattern = "%-%" + String.format("%04d", seq);
                } catch (NumberFormatException e) {
                    String mappedId = mapToDerbyInternId(userId);
                    try {
                        int seq = Integer.parseInt(mappedId);
                        likePattern = "%-%" + String.format("%04d", seq);
                    } catch (NumberFormatException ex) {
                        likePattern = userId;
                    }
                }
                ps.setString(2, likePattern);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        status = rs.getString("STATUS");
                    }
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Error fetching status for User ID: " + userId, e, null, context);
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
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to count pending activity submissions", e, null, context);
            System.err.println("Error executing getPendingLogsCount query: " + e.getMessage());
            e.printStackTrace();
        }
        return count;
    }

    /**
     * GET INTERN BY ID: Fetches a single intern by their ID (DBMS 1 - Apache Derby).
     */
    public static User getInternById(String internId, ServletContext context) {
        checkDerbySchema(context);
        String mappedId = mapToDerbyInternId(internId);
        String sql = "SELECT * FROM INTERN WHERE INTERN_ID = ?";
        try (Connection conn = DBConnection.getDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, mappedId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUser(rs, rs.getString("ROLE"), context);
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to query intern profile for ID: " + internId, e, null, context);
            e.printStackTrace();
        }
        return null;
    }

    /**
     * GET SUBMISSIONS BY USER ID: Fetches activity logs for a specific intern (DBMS 2 - MySQL).
     */
    public static List<ActivitySubmission> getSubmissionsByUserId(String userId, ServletContext context) {
        List<ActivitySubmission> list = new ArrayList<>();
        
        // Get the specific intern profile from Derby to map references
        User profile = getInternById(userId, context);

        String sql = "SELECT * FROM ACTIVITY_SUBMISSIONS WHERE USER_ID = ? OR USER_ID LIKE ? ORDER BY DATE_SUBMITTED DESC";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context)) {
            if (conn == null) {
                System.err.println("CRITICAL: MySQL connection failed inside getSubmissionsByUserId!");
                return list;
            }
            try (PreparedStatement ps = conn.prepareStatement(sql)) {

                ps.setString(1, userId);
                
                String likePattern = "";
                try {
                    int seq = Integer.parseInt(userId);
                    likePattern = "%-%" + String.format("%04d", seq);
                } catch (NumberFormatException e) {
                    String mappedId = mapToDerbyInternId(userId);
                    try {
                        int seq = Integer.parseInt(mappedId);
                        likePattern = "%-%" + String.format("%04d", seq);
                    } catch (NumberFormatException ex) {
                        likePattern = userId;
                    }
                }
                ps.setString(2, likePattern);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        ActivitySubmission sub = new ActivitySubmission();
                        sub.setSubmissionId(rs.getString("SUBMISSION_ID"));
                        sub.setUserId(userId);
                        sub.setDateSubmitted(rs.getDate("DATE_SUBMITTED"));
                        sub.setDescription(rs.getString("DESCRIPTION"));
                        sub.setLearningReflection(rs.getString("LEARNING_REFLECTION"));
                        sub.setSupportingFile(rs.getString("SUPPORTING_FILE"));
                        sub.setOriginalFileName(rs.getString("ORIGINAL_FILE_NAME"));
                        sub.setStatus(rs.getString("STATUS"));

                        if (profile != null) {
                            sub.setInternName(profile.getFullName());
                            sub.setAssignedOffice(profile.getOffice());
                        } else {
                            sub.setInternName("Intern Profile");
                            sub.setAssignedOffice("Main Administration Office");
                        }
                        list.add(sub);
                    }
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to query submissions for User ID: " + userId, e, null, context);
            e.printStackTrace();
        }
        return list;
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
        u.setMiddleName(rs.getString("MIDDLE_NAME"));
        u.setLastName(rs.getString("LAST_NAME"));
        u.setEmail(rs.getString("EMAIL"));
        u.setPassword(rs.getString("PASSWORD"));
        u.setRole(role); 
        
        try {
            u.setCreatedAt(rs.getTimestamp("CREATED_AT"));
        } catch (SQLException ex) {
            // Fallback for schema compatibility
        }
        
        try {
            u.setUniversity(rs.getString("UNIVERSITY"));
            u.setOffice(rs.getString("OFFICE"));
            u.setRoleCode(rs.getString("ROLE_CODE"));
            u.setCity(rs.getString("CITY"));
            try {
                u.setAvatarPath(rs.getString("AVATAR_PATH"));
            } catch (SQLException ex) {
                // Fallback for schema compatibility or Admins
            }
            try {
                u.setResetHours(rs.getBoolean("RESET_HOURS"));
            } catch (SQLException ex) {
                // Fallback for schema compatibility
            }
            try {
                u.setBaselineHours(rs.getDouble("BASELINE_HOURS"));
            } catch (SQLException ex) {
                u.setBaselineHours(148.5); // Fallback for schema compatibility
            }
            
            if (!"Admin".equalsIgnoreCase(role)) {
                u.setLogStatus(getIndividualStatus(id, context));
            }
        } catch (SQLException e) {
            // Ignored for Admins
        }
        return u;
    }

    public static String mapToDerbyInternId(String userId) {
        if (userId == null) return null;
        
        // If the database actually contains the full ID like INT2026-70001, we shouldn't truncate it.
        // We will just return the original ID. The caller's SQL query will match exactly.
        return userId;
    }

    public static String generateInternId(Connection conn) throws SQLException {
        int currentYear = java.time.Year.now().getValue();
        int companyAge = currentYear - 2020 + 1;
        String prefix = "INT" + currentYear + "-" + companyAge;
        String likePattern = prefix + "%";
        
        String sql = "SELECT INTERN_ID FROM APP.INTERN WHERE INTERN_ID LIKE ? ORDER BY INTERN_ID DESC";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, likePattern);
            ps.setMaxRows(1);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String lastId = rs.getString("INTERN_ID");
                    int dashIndex = lastId.lastIndexOf('-');
                    if (dashIndex != -1 && dashIndex < lastId.length() - 1) {
                        String seqPartStr = lastId.substring(dashIndex + 1);
                        String companyAgeStr = String.valueOf(companyAge);
                        if (seqPartStr.startsWith(companyAgeStr)) {
                            String seqNumStr = seqPartStr.substring(companyAgeStr.length());
                            try {
                                int seqNum = Integer.parseInt(seqNumStr);
                                int nextSeqNum = seqNum + 1;
                                return prefix + String.format("%04d", nextSeqNum);
                            } catch (NumberFormatException e) {
                                // ignore
                            }
                        }
                    }
                }
            }
        }
        return prefix + "0001";
    }

    public static String generateAdminId(Connection conn) throws SQLException {
        int currentYear = java.time.Year.now().getValue();
        String prefix = "ADM" + currentYear + "-";
        String likePattern = prefix + "%";
        
        String sql = "SELECT ADMIN_ID FROM APP.ADMIN WHERE ADMIN_ID LIKE ? ORDER BY ADMIN_ID DESC";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, likePattern);
            ps.setMaxRows(1);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String lastId = rs.getString("ADMIN_ID");
                    int dashIndex = lastId.lastIndexOf('-');
                    if (dashIndex != -1 && dashIndex < lastId.length() - 1) {
                        String seqPartStr = lastId.substring(dashIndex + 1);
                        try {
                            int seqNum = Integer.parseInt(seqPartStr);
                            int nextSeqNum = seqNum + 1;
                            return prefix + String.format("%04d", nextSeqNum);
                        } catch (NumberFormatException e) {
                            // ignore
                        }
                    }
                }
            }
        }
        return prefix + "0001";
    }

    public static boolean addIntern(User internUser, String birthMonth, int birthDate, int birthYear, int age, String contactNum, ServletContext context) {
        String sql = "INSERT INTO APP.INTERN (FIRST_NAME, MIDDLE_NAME, LAST_NAME, BIRTH_MONTH, BIRTH_DATE, BIRTH_YEAR, AGE, CITY, CONTACT_NUM, UNIVERSITY, ROLE, ROLE_CODE, OFFICE, EMAIL, PASSWORD) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return false;
            
            // Safeguard password encryption
            String rawPassword = internUser.getPassword();
            if (rawPassword != null && !rawPassword.startsWith("enc:")) {
                internUser.setPassword(util.CryptoUtil.hashPassword(rawPassword));
            }
            
            try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, internUser.getFirstName());
                ps.setString(2, internUser.getMiddleName());
                ps.setString(3, internUser.getLastName());
                ps.setString(4, birthMonth);
                ps.setInt(5, birthDate);
                ps.setInt(6, birthYear);
                ps.setInt(7, age);
                ps.setString(8, internUser.getCity());
                ps.setString(9, contactNum);
                ps.setString(10, internUser.getUniversity());
                ps.setString(11, internUser.getRole());
                ps.setString(12, internUser.getRoleCode());
                ps.setString(13, internUser.getOffice());
                ps.setString(14, internUser.getEmail());
                ps.setString(15, internUser.getPassword());
                
                boolean success = ps.executeUpdate() > 0;
                if (success) {
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (rs.next()) {
                            int generatedId = rs.getInt(1);
                            internUser.setId(String.valueOf(generatedId));
                        }
                    }
                }
                return success;
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to insert new Intern profile: " + internUser.getEmail(), e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static boolean addAdmin(User adminUser, ServletContext context) {
        String sql = "INSERT INTO APP.ADMIN (FIRST_NAME, MIDDLE_NAME, LAST_NAME, ROLE_CODE, EMAIL, PASSWORD) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return false;
            
            // Safeguard password encryption
            String rawPassword = adminUser.getPassword();
            if (rawPassword != null && !rawPassword.startsWith("enc:")) {
                adminUser.setPassword(util.CryptoUtil.hashPassword(rawPassword));
            }
            
            try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, adminUser.getFirstName());
                ps.setString(2, adminUser.getMiddleName());
                ps.setString(3, adminUser.getLastName());
                ps.setString(4, "admin");
                ps.setString(5, adminUser.getEmail());
                ps.setString(6, adminUser.getPassword());
                
                boolean success = ps.executeUpdate() > 0;
                if (success) {
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (rs.next()) {
                            int generatedId = rs.getInt(1);
                            adminUser.setId(String.valueOf(generatedId));
                        }
                    }
                }
                return success;
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to insert new Admin profile: " + adminUser.getEmail(), e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static String generateSubmissionId(Connection conn, String roleCode) throws SQLException {
        java.time.LocalDate today = java.time.LocalDate.now();
        String dateStr = today.format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd"));
        String prefix = dateStr + "-" + (roleCode != null ? roleCode.toUpperCase() : "INT") + "-";
        
        String query = "SELECT SUBMISSION_ID FROM ACTIVITY_SUBMISSIONS WHERE SUBMISSION_ID LIKE ? ORDER BY SUBMISSION_ID DESC LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, dateStr + "-%");
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String lastId = rs.getString("SUBMISSION_ID");
                    String[] parts = lastId.split("-");
                    if (parts.length >= 3) {
                        try {
                            int seq = Integer.parseInt(parts[parts.length - 1]);
                            return String.format("%s%04d", prefix, seq + 1);
                        } catch (NumberFormatException e) {
                            // ignore and fallback
                        }
                    }
                }
            }
        }
        
        // Suffix fallback counting all submissions
        String queryOverall = "SELECT SUBMISSION_ID FROM ACTIVITY_SUBMISSIONS ORDER BY SUBMISSION_ID DESC LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(queryOverall);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                String lastId = rs.getString("SUBMISSION_ID");
                String[] parts = lastId.split("-");
                if (parts.length >= 3) {
                    try {
                        int seq = Integer.parseInt(parts[parts.length - 1]);
                        return String.format("%s%04d", prefix, seq + 1);
                    } catch (NumberFormatException e) {
                        // ignore
                    }
                }
            }
        }
        
        return prefix + "0001";
    }

    /**
     * UPDATE INTERN: Modifies an existing intern record (DBMS 1 - Apache Derby).
     * If password is blank/null, keeps the existing password unchanged.
     */
    public static boolean updateIntern(User internUser, String birthMonth, int birthDate, int birthYear,
            int age, String contactNum, boolean changePassword, ServletContext context) {
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return false;

            String sql;
            if (changePassword) {
                sql = "UPDATE APP.INTERN SET FIRST_NAME=?, MIDDLE_NAME=?, LAST_NAME=?, BIRTH_MONTH=?, " +
                      "BIRTH_DATE=?, BIRTH_YEAR=?, AGE=?, CITY=?, CONTACT_NUM=?, UNIVERSITY=?, " +
                      "ROLE=?, ROLE_CODE=?, OFFICE=?, EMAIL=?, PASSWORD=? WHERE INTERN_ID=?";
            } else {
                sql = "UPDATE APP.INTERN SET FIRST_NAME=?, MIDDLE_NAME=?, LAST_NAME=?, BIRTH_MONTH=?, " +
                      "BIRTH_DATE=?, BIRTH_YEAR=?, AGE=?, CITY=?, CONTACT_NUM=?, UNIVERSITY=?, " +
                      "ROLE=?, ROLE_CODE=?, OFFICE=?, EMAIL=? WHERE INTERN_ID=?";
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, internUser.getFirstName());
                ps.setString(2, internUser.getMiddleName());
                ps.setString(3, internUser.getLastName());
                ps.setString(4, birthMonth);
                ps.setInt(5, birthDate);
                ps.setInt(6, birthYear);
                ps.setInt(7, age);
                ps.setString(8, internUser.getCity());
                ps.setString(9, contactNum);
                ps.setString(10, internUser.getUniversity());
                ps.setString(11, internUser.getRole());
                ps.setString(12, internUser.getRoleCode());
                ps.setString(13, internUser.getOffice());
                ps.setString(14, internUser.getEmail());
                if (changePassword) {
                    String pwd = internUser.getPassword();
                    if (pwd != null && !pwd.startsWith("enc:")) {
                        pwd = util.CryptoUtil.hashPassword(pwd);
                        internUser.setPassword(pwd);
                    }
                    ps.setString(15, pwd);
                    ps.setString(16, internUser.getId());
                } else {
                    ps.setString(15, internUser.getId());
                }
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to update Intern profile: " + internUser.getId(), e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    /**
     * DELETE INTERN: Removes an intern record from Apache Derby.
     */
    public static boolean deleteIntern(String internId, ServletContext context) {
        String sql = "DELETE FROM APP.INTERN WHERE INTERN_ID = ?";
        try (Connection conn = DBConnection.getDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, internId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to delete Intern profile: " + internId, e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    /**
     * UPDATE SUBMISSION: Modifies description and date of an activity log (DBMS 2 - MySQL).
     */
    public static boolean updateSubmission(String submissionId, String description, String learningReflection, String dateSubmitted, ServletContext context) {
        String sql = "UPDATE ACTIVITY_SUBMISSIONS SET DESCRIPTION=?, LEARNING_REFLECTION=?, DATE_SUBMITTED=? WHERE SUBMISSION_ID=?";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, description);
            ps.setString(2, learningReflection);
            ps.setDate(3, java.sql.Date.valueOf(dateSubmitted));
            ps.setString(4, submissionId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to update submission: " + submissionId, e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    /**
     * DELETE SUBMISSION: Removes an activity log entry from MySQL.
     */
    public static boolean deleteSubmission(String submissionId, ServletContext context) {
        String sql = "DELETE FROM ACTIVITY_SUBMISSIONS WHERE SUBMISSION_ID = ?";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, submissionId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to delete submission: " + submissionId, e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static boolean addActivitySubmission(ActivitySubmission sub, ServletContext context) {
        String sql = "INSERT INTO ACTIVITY_SUBMISSIONS (SUBMISSION_ID, USER_ID, DATE_SUBMITTED, DESCRIPTION, LEARNING_REFLECTION, SUPPORTING_FILE, ORIGINAL_FILE_NAME, STATUS) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context)) {
            if (conn == null) {
                System.err.println("CRITICAL: MySQL connection failed inside addActivitySubmission!");
                return false;
            }
            
            // If submissionId is empty or null, generate it
            if (sub.getSubmissionId() == null || sub.getSubmissionId().trim().isEmpty()) {
                // Find roleCode of the user
                User user = getInternById(sub.getUserId(), context);
                String roleCode = (user != null) ? user.getRoleCode() : "INT";
                sub.setSubmissionId(generateSubmissionId(conn, roleCode));
            }
            
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, sub.getSubmissionId());
                ps.setString(2, sub.getUserId());
                ps.setDate(3, sub.getDateSubmitted());
                ps.setString(4, sub.getDescription());
                ps.setString(5, sub.getLearningReflection());
                ps.setString(6, sub.getSupportingFile());
                ps.setString(7, sub.getOriginalFileName());
                ps.setString(8, sub.getStatus());
                return ps.executeUpdate() > 0;
            }
        } catch (Exception e) {
            System.err.println("Error adding activity submission: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public static synchronized void migrateLegacyPasswords(ServletContext context) {
        if (passwordsMigrated) {
            return;
        }
        System.out.println("MIGRATION: Starting automatic password encryption migration for Derby database...");
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) {
                System.err.println("MIGRATION ERROR: Failed to connect to Derby database for migration.");
                return;
            }
            
            // 1. Migrate ADMIN table
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT ADMIN_ID, PASSWORD FROM APP.ADMIN")) {
                while (rs.next()) {
                    String id = rs.getString("ADMIN_ID");
                    String pwd = rs.getString("PASSWORD");
                    if (pwd != null && !pwd.startsWith("enc:")) {
                        String encrypted = util.CryptoUtil.hashPassword(pwd);
                        try (PreparedStatement ps = conn.prepareStatement("UPDATE APP.ADMIN SET PASSWORD = ? WHERE ADMIN_ID = ?")) {
                            ps.setString(1, encrypted);
                            ps.setString(2, id);
                            ps.executeUpdate();
                            System.out.println("MIGRATION: Encrypted password for ADMIN ID " + id);
                        }
                    }
                }
            } catch (SQLException e) {
                // Fallback without schema name
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT ADMIN_ID, PASSWORD FROM ADMIN")) {
                    while (rs.next()) {
                        String id = rs.getString("ADMIN_ID");
                        String pwd = rs.getString("PASSWORD");
                        if (pwd != null && !pwd.startsWith("enc:")) {
                            String encrypted = util.CryptoUtil.hashPassword(pwd);
                            try (PreparedStatement ps = conn.prepareStatement("UPDATE ADMIN SET PASSWORD = ? WHERE ADMIN_ID = ?")) {
                                ps.setString(1, encrypted);
                                ps.setString(2, id);
                                ps.executeUpdate();
                                System.out.println("MIGRATION: Encrypted password for ADMIN ID " + id);
                            }
                        }
                    }
                } catch (SQLException ex) {
                    System.err.println("MIGRATION ERROR: Failed to query/update ADMIN table: " + ex.getMessage());
                }
            }
            
            // 2. Migrate INTERN table
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT INTERN_ID, PASSWORD FROM APP.INTERN")) {
                while (rs.next()) {
                    String id = rs.getString("INTERN_ID");
                    String pwd = rs.getString("PASSWORD");
                    if (pwd != null && !pwd.startsWith("enc:")) {
                        String encrypted = util.CryptoUtil.hashPassword(pwd);
                        try (PreparedStatement ps = conn.prepareStatement("UPDATE APP.INTERN SET PASSWORD = ? WHERE INTERN_ID = ?")) {
                            ps.setString(1, encrypted);
                            ps.setString(2, id);
                            ps.executeUpdate();
                            System.out.println("MIGRATION: Encrypted password for INTERN ID " + id);
                        }
                    }
                }
            } catch (SQLException e) {
                // Fallback without schema name
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT INTERN_ID, PASSWORD FROM INTERN")) {
                    while (rs.next()) {
                        String id = rs.getString("INTERN_ID");
                        String pwd = rs.getString("PASSWORD");
                        if (pwd != null && !pwd.startsWith("enc:")) {
                            String encrypted = util.CryptoUtil.hashPassword(pwd);
                            try (PreparedStatement ps = conn.prepareStatement("UPDATE INTERN SET PASSWORD = ? WHERE INTERN_ID = ?")) {
                                ps.setString(1, encrypted);
                                ps.setString(2, id);
                                ps.executeUpdate();
                                System.out.println("MIGRATION: Encrypted password for INTERN ID " + id);
                            }
                        }
                    }
                } catch (SQLException ex) {
                    System.err.println("MIGRATION ERROR: Failed to query/update INTERN table: " + ex.getMessage());
                }
            }
            
            System.out.println("MIGRATION SUCCESS: Derby database password migration completed successfully.");
            passwordsMigrated = true;
        } catch (Exception e) {
            System.err.println("MIGRATION ERROR: Unexpected error during migration: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public static void checkDerbySchema(ServletContext context) {
        migrateLegacyPasswords(context);
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return;
            DatabaseMetaData meta = conn.getMetaData();
            boolean columnExists = false;
            try (ResultSet rs = meta.getColumns(null, "APP", "INTERN", "RESET_HOURS")) {
                if (rs.next()) {
                    columnExists = true;
                }
            }
            if (!columnExists) {
                try (ResultSet rs = meta.getColumns(null, null, "INTERN", "RESET_HOURS")) {
                    if (rs.next()) {
                        columnExists = true;
                    }
                }
            }
            if (!columnExists) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.executeUpdate("ALTER TABLE INTERN ADD RESET_HOURS BOOLEAN DEFAULT FALSE");
                    System.out.println("SUCCESS: Table 'INTERN' altered. Column 'RESET_HOURS' added.");
                } catch (SQLException e) {
                    try (Statement stmt = conn.createStatement()) {
                        stmt.executeUpdate("ALTER TABLE APP.INTERN ADD RESET_HOURS BOOLEAN DEFAULT FALSE");
                        System.out.println("SUCCESS: Table 'APP.INTERN' altered. Column 'RESET_HOURS' added.");
                    } catch (SQLException ex) {
                        System.err.println("Failed to alter INTERN table: " + ex.getMessage());
                    }
                }
            }

            boolean baselineExists = false;
            try (ResultSet rs = meta.getColumns(null, "APP", "INTERN", "BASELINE_HOURS")) {
                if (rs.next()) {
                    baselineExists = true;
                }
            }
            if (!baselineExists) {
                try (ResultSet rs = meta.getColumns(null, null, "INTERN", "BASELINE_HOURS")) {
                    if (rs.next()) {
                        baselineExists = true;
                    }
                }
            }
            if (!baselineExists) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.executeUpdate("ALTER TABLE INTERN ADD BASELINE_HOURS DOUBLE DEFAULT 148.5");
                    System.out.println("SUCCESS: Table 'INTERN' altered. Column 'BASELINE_HOURS' added.");
                } catch (SQLException e) {
                    try (Statement stmt = conn.createStatement()) {
                        stmt.executeUpdate("ALTER TABLE APP.INTERN ADD BASELINE_HOURS DOUBLE DEFAULT 148.5");
                        System.out.println("SUCCESS: Table 'APP.INTERN' altered. Column 'BASELINE_HOURS' added.");
                    } catch (SQLException ex) {
                        System.err.println("Failed to alter INTERN table for BASELINE_HOURS: " + ex.getMessage());
                    }
                }
            }

            boolean createdAtInternExists = false;
            try (ResultSet rs = meta.getColumns(null, "APP", "INTERN", "CREATED_AT")) {
                if (rs.next()) {
                    createdAtInternExists = true;
                }
            }
            if (!createdAtInternExists) {
                try (ResultSet rs = meta.getColumns(null, null, "INTERN", "CREATED_AT")) {
                    if (rs.next()) {
                        createdAtInternExists = true;
                    }
                }
            }
            if (!createdAtInternExists) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.executeUpdate("ALTER TABLE INTERN ADD CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
                    System.out.println("SUCCESS: Table 'INTERN' altered. Column 'CREATED_AT' added.");
                } catch (SQLException e) {
                    try (Statement stmt = conn.createStatement()) {
                        stmt.executeUpdate("ALTER TABLE APP.INTERN ADD CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
                        System.out.println("SUCCESS: Table 'APP.INTERN' altered. Column 'CREATED_AT' added.");
                    } catch (SQLException ex) {
                        System.err.println("Failed to alter INTERN table for CREATED_AT: " + ex.getMessage());
                    }
                }
            }

            boolean createdAtAdminExists = false;
            try (ResultSet rs = meta.getColumns(null, "APP", "ADMIN", "CREATED_AT")) {
                if (rs.next()) {
                    createdAtAdminExists = true;
                }
            }
            if (!createdAtAdminExists) {
                try (ResultSet rs = meta.getColumns(null, null, "ADMIN", "CREATED_AT")) {
                    if (rs.next()) {
                        createdAtAdminExists = true;
                    }
                }
            }
            if (!createdAtAdminExists) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.executeUpdate("ALTER TABLE ADMIN ADD CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
                    System.out.println("SUCCESS: Table 'ADMIN' altered. Column 'CREATED_AT' added.");
                } catch (SQLException e) {
                    try (Statement stmt = conn.createStatement()) {
                        stmt.executeUpdate("ALTER TABLE APP.ADMIN ADD CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
                        System.out.println("SUCCESS: Table 'APP.ADMIN' altered. Column 'CREATED_AT' added.");
                    } catch (SQLException ex) {
                        System.err.println("Failed to alter ADMIN table for CREATED_AT: " + ex.getMessage());
                    }
                }
            }

            boolean avatarPathExists = false;
            try (ResultSet rs = meta.getColumns(null, "APP", "INTERN", "AVATAR_PATH")) {
                if (rs.next()) {
                    avatarPathExists = true;
                }
            }
            if (!avatarPathExists) {
                try (ResultSet rs = meta.getColumns(null, null, "INTERN", "AVATAR_PATH")) {
                    if (rs.next()) {
                        avatarPathExists = true;
                    }
                }
            }
            if (!avatarPathExists) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.executeUpdate("ALTER TABLE INTERN ADD AVATAR_PATH VARCHAR(255)");
                    System.out.println("SUCCESS: Table 'INTERN' altered. Column 'AVATAR_PATH' added.");
                } catch (SQLException e) {
                    try (Statement stmt = conn.createStatement()) {
                        stmt.executeUpdate("ALTER TABLE APP.INTERN ADD AVATAR_PATH VARCHAR(255)");
                        System.out.println("SUCCESS: Table 'APP.INTERN' altered. Column 'AVATAR_PATH' added.");
                    } catch (SQLException ex) {
                        System.err.println("Failed to alter INTERN table for AVATAR_PATH: " + ex.getMessage());
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("Error checking Derby schema: " + e.getMessage());
        }
    }

    public static boolean deleteCustomSubmissionsByUserId(String userId, ServletContext context) {
        String sql = "DELETE FROM ACTIVITY_SUBMISSIONS WHERE (USER_ID = ? OR USER_ID LIKE ?) AND DESCRIPTION LIKE '%(Hours Spent:%'";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context)) {
            if (conn == null) return false;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, userId);
                String likePattern = "";
                try {
                    int seq = Integer.parseInt(userId);
                    likePattern = "%-%" + String.format("%04d", seq);
                } catch (NumberFormatException e) {
                    String mappedId = mapToDerbyInternId(userId);
                    try {
                        int seq = Integer.parseInt(mappedId);
                        likePattern = "%-%" + String.format("%04d", seq);
                    } catch (NumberFormatException ex) {
                        likePattern = userId;
                    }
                }
                ps.setString(2, likePattern);
                return ps.executeUpdate() >= 0;
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to delete custom submissions for User ID: " + userId, e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static boolean setResetHoursFlag(String internId, boolean flag, ServletContext context) {
        checkDerbySchema(context);
        String mappedId = mapToDerbyInternId(internId);
        
        if (flag) {
            deleteCustomSubmissionsByUserId(internId, context);
            try (Connection conn = DBConnection.getDerbyConnection(context)) {
                String sqlBaseline = "UPDATE INTERN SET BASELINE_HOURS = 0.0 WHERE INTERN_ID = ?";
                try (PreparedStatement ps = conn.prepareStatement(sqlBaseline)) {
                    ps.setString(1, mappedId);
                    ps.executeUpdate();
                }
            } catch (Exception e) {
                try {
                    String sqlBaselineApp = "UPDATE APP.INTERN SET BASELINE_HOURS = 0.0 WHERE INTERN_ID = ?";
                    try (Connection conn = DBConnection.getDerbyConnection(context);
                         PreparedStatement ps = conn.prepareStatement(sqlBaselineApp)) {
                        ps.setString(1, mappedId);
                        ps.executeUpdate();
                    }
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        }
        
        String sql = "UPDATE INTERN SET RESET_HOURS = ? WHERE INTERN_ID = ?";
        try (Connection conn = DBConnection.getDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBoolean(1, flag);
            ps.setString(2, mappedId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            try {
                String sqlApp = "UPDATE APP.INTERN SET RESET_HOURS = ? WHERE INTERN_ID = ?";
                try (Connection conn = DBConnection.getDerbyConnection(context);
                     PreparedStatement ps = conn.prepareStatement(sqlApp)) {
                    ps.setBoolean(1, flag);
                    ps.setString(2, mappedId);
                    return ps.executeUpdate() > 0;
                }
            } catch (Exception ex) {
                util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to update RESET_HOURS flag for intern: " + internId, ex, null, context);
                ex.printStackTrace();
            }
        }
        return false;
    }

    private static boolean mysqlSchemaChecked = false;

    public static void checkMySQLSchema(ServletContext context) {
        if (mysqlSchemaChecked) return;
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context)) {
            if (conn == null) {
                System.err.println("CRITICAL: MySQL connection failed inside checkMySQLSchema!");
                return;
            }
            try (Statement stmt = conn.createStatement()) {
                stmt.executeUpdate("CREATE TABLE IF NOT EXISTS announcements ("
                        + "id INT AUTO_INCREMENT PRIMARY KEY, "
                        + "title VARCHAR(255) NOT NULL, "
                        + "content TEXT NOT NULL, "
                        + "target_type VARCHAR(50) NOT NULL, "
                        + "target_value VARCHAR(255), "
                        + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                        + "sender_id VARCHAR(50) NOT NULL, "
                        + "sender_name VARCHAR(255) NOT NULL"
                        + ")");
                
                stmt.executeUpdate("CREATE TABLE IF NOT EXISTS messages ("
                        + "id INT AUTO_INCREMENT PRIMARY KEY, "
                        + "sender_id VARCHAR(50) NOT NULL, "
                        + "receiver_id VARCHAR(50) NOT NULL, "
                        + "message_text TEXT NOT NULL, "
                        + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                        + "is_read BOOLEAN DEFAULT FALSE"
                        + ")");
                
                System.out.println("SUCCESS: Checked and verified MySQL announcements and messages tables.");
                mysqlSchemaChecked = true;
            }
        } catch (Exception e) {
            System.err.println("Error verifying MySQL schema: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public static boolean addAnnouncement(Announcement ann, ServletContext context) {
        checkMySQLSchema(context);
        String sql = "INSERT INTO announcements (title, content, target_type, target_value, sender_id, sender_name) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, ann.getTitle());
            ps.setString(2, ann.getContent());
            ps.setString(3, ann.getTargetType());
            ps.setString(4, ann.getTargetValue());
            ps.setString(5, ann.getSenderId());
            ps.setString(6, ann.getSenderName());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to add announcement: " + ann.getTitle(), e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static List<Announcement> getAllAnnouncements(ServletContext context) {
        checkMySQLSchema(context);
        List<Announcement> list = new ArrayList<>();
        String sql = "SELECT * FROM announcements ORDER BY created_at DESC";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Announcement ann = new Announcement();
                ann.setId(rs.getInt("id"));
                ann.setTitle(rs.getString("title"));
                ann.setContent(rs.getString("content"));
                ann.setTargetType(rs.getString("target_type"));
                ann.setTargetValue(rs.getString("target_value"));
                ann.setCreatedAt(rs.getTimestamp("created_at"));
                ann.setSenderId(rs.getString("sender_id"));
                ann.setSenderName(rs.getString("sender_name"));
                list.add(ann);
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to retrieve all announcements", e, null, context);
            e.printStackTrace();
        }
        return list;
    }

    public static List<Announcement> getAnnouncementsForIntern(String office, String role, String city, ServletContext context) {
        checkMySQLSchema(context);
        List<Announcement> list = new ArrayList<>();
        String sql = "SELECT * FROM announcements WHERE target_type = 'ALL' "
                   + "OR (target_type = 'OFFICE' AND target_value = ?) "
                   + "OR (target_type = 'ROLE' AND target_value = ?) "
                   + "OR (target_type = 'CITY' AND target_value = ?) "
                   + "ORDER BY created_at DESC";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, office);
            ps.setString(2, role);
            ps.setString(3, city != null ? city.trim() : "");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Announcement ann = new Announcement();
                    ann.setId(rs.getInt("id"));
                    ann.setTitle(rs.getString("title"));
                    ann.setContent(rs.getString("content"));
                    ann.setTargetType(rs.getString("target_type"));
                    ann.setTargetValue(rs.getString("target_value"));
                    ann.setCreatedAt(rs.getTimestamp("created_at"));
                    ann.setSenderId(rs.getString("sender_id"));
                    ann.setSenderName(rs.getString("sender_name"));
                    list.add(ann);
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to retrieve announcements for intern", e, null, context);
            e.printStackTrace();
        }
        return list;
    }

    public static boolean deleteAnnouncement(int id, ServletContext context) {
        checkMySQLSchema(context);
        String sql = "DELETE FROM announcements WHERE id = ?";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to delete announcement with id: " + id, e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static List<User> getAllAdmins(ServletContext context) {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM ADMIN";
        try (Connection conn = DBConnection.getDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                User u = mapResultSetToUser(rs, "Admin", context);
                list.add(u);
            }
        } catch (Exception e) {
            String sqlApp = "SELECT * FROM APP.ADMIN";
            try (Connection conn = DBConnection.getDerbyConnection(context);
                 PreparedStatement ps = conn.prepareStatement(sqlApp);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    User u = mapResultSetToUser(rs, "Admin", context);
                    list.add(u);
                }
            } catch (Exception ex) {
                util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to retrieve admin profiles", ex, null, context);
                ex.printStackTrace();
            }
        }
        return list;
    }

    public static boolean sendMessage(Message msg, ServletContext context) {
        checkMySQLSchema(context);
        String sql = "INSERT INTO messages (sender_id, receiver_id, message_text, is_read) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, msg.getSenderId());
            ps.setString(2, msg.getReceiverId());
            ps.setString(3, msg.getMessageText());
            ps.setBoolean(4, false);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to send message from " + msg.getSenderId() + " to " + msg.getReceiverId(), e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static List<Message> getMessageHistory(String user1, String user2, ServletContext context) {
        checkMySQLSchema(context);
        List<Message> list = new ArrayList<>();
        String sql = "SELECT * FROM messages WHERE (sender_id = ? AND receiver_id = ?) "
                   + "OR (sender_id = ? AND receiver_id = ?) ORDER BY created_at ASC";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, user1);
            ps.setString(2, user2);
            ps.setString(3, user2);
            ps.setString(4, user1);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Message m = new Message();
                    m.setId(rs.getInt("id"));
                    m.setSenderId(rs.getString("sender_id"));
                    m.setReceiverId(rs.getString("receiver_id"));
                    m.setMessageText(rs.getString("message_text"));
                    m.setCreatedAt(rs.getTimestamp("created_at"));
                    m.setIsRead(rs.getBoolean("is_read"));
                    list.add(m);
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to fetch message history", e, null, context);
            e.printStackTrace();
        }
        return list;
    }

    public static Map<String, Integer> getUnreadCounts(String userId, ServletContext context) {
        checkMySQLSchema(context);
        Map<String, Integer> map = new HashMap<>();
        String sql = "SELECT sender_id, COUNT(*) AS cnt FROM messages WHERE receiver_id = ? AND is_read = false GROUP BY sender_id";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getString("sender_id"), rs.getInt("cnt"));
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to fetch unread message counts", e, null, context);
            e.printStackTrace();
        }
        return map;
    }

    public static Map<String, java.sql.Timestamp> getLastMessageTimes(String userId, ServletContext context) {
        checkMySQLSchema(context);
        Map<String, java.sql.Timestamp> map = new HashMap<>();
        String sql = "SELECT "
                   + "  CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END AS contact_id, "
                   + "  MAX(created_at) AS last_time "
                   + "FROM messages "
                   + "WHERE sender_id = ? OR receiver_id = ? "
                   + "GROUP BY CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setString(2, userId);
            ps.setString(3, userId);
            ps.setString(4, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getString("contact_id"), rs.getTimestamp("last_time"));
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to fetch last message times", e, null, context);
            e.printStackTrace();
        }
        return map;
    }

    public static boolean markMessagesAsRead(String senderId, String receiverId, ServletContext context) {
        checkMySQLSchema(context);
        String sql = "UPDATE messages SET is_read = true WHERE sender_id = ? AND receiver_id = ? AND is_read = false";
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, senderId);
            ps.setString(2, receiverId);
            return ps.executeUpdate() >= 0;
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to mark messages as read", e, null, context);
            e.printStackTrace();
            return false;
        }
    }

    public static boolean updateAvatarPath(String userId, String path, ServletContext context) {
        String sql = "UPDATE APP.INTERN SET AVATAR_PATH = ? WHERE INTERN_ID = ?";
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return false;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, path);
                ps.setString(2, userId);
                return ps.executeUpdate() > 0;
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to update avatar path for user " + userId, e, null, context);
            e.printStackTrace();
            return false;
        }
    }
}