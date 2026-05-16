package model;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletContext;
import util.DBConnection;

/**
 * Data Access Object
 * Handles all database interactions for the Authentication and Dashboard modules.
 */
public class UserDAO {

    // --- 1. VALIDATE USER (For Login) ---
    public static User validateUser(String email, String hashedPassword, ServletContext context) {
        User user = null;

        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return null;

            // Check ADMIN Table
            String adminSql = "SELECT * FROM ADMIN WHERE EMAIL = ? AND PASSWORD = ?";
            try (PreparedStatement psAdmin = conn.prepareStatement(adminSql)) {
                psAdmin.setString(1, email);
                psAdmin.setString(2, hashedPassword);
                try (ResultSet rsAdmin = psAdmin.executeQuery()) {
                    if (rsAdmin.next()) {
                        user = mapResultSetToUser(rsAdmin, "Admin");
                    }
                }
            }

            // If not found in Admin, check INTERN Table
            if (user == null) {
                String internSql = "SELECT * FROM INTERN WHERE EMAIL = ? AND PASSWORD = ?";
                try (PreparedStatement psIntern = conn.prepareStatement(internSql)) {
                    psIntern.setString(1, email);
                    psIntern.setString(2, hashedPassword);
                    try (ResultSet rsIntern = psIntern.executeQuery()) {
                        if (rsIntern.next()) {
                            user = mapResultSetToUser(rsIntern, rsIntern.getString("ROLE_CODE"));
                        }
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return user;
    }

    // --- 2. GET ALL INTERNS (For Dashboard Master List) ---
    public static List<User> getAllInterns(ServletContext context) {
        List<User> list = new ArrayList<>();
        
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return list;

            String sql = "SELECT * FROM INTERN ORDER BY LAST_NAME ASC";
            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    User u = mapResultSetToUser(rs, rs.getString("ROLE_CODE"));
                    
                    // Fetch the live status for this specific intern from the OJT database
                    u.setLogStatus(getIndividualStatus(u.getId(), context));
                    
                    list.add(u);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // --- 3. GET INDIVIDUAL STATUS (Checks OJTDB for Activity) ---
    public static String getIndividualStatus(int userId, ServletContext context) {
        String status = "No Log"; 
        
        try (Connection conn = DBConnection.getOJTDerbyConnection(context)) {
            if (conn == null) return status;

            String sql = "SELECT STATUS FROM APP.ACTIVITY_SUBMISSIONS WHERE USER_ID = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        status = rs.getString("STATUS");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return status;
    }

    // --- 4. GET PENDING LOGS COUNT (For Admin Dashboard Stats Card) ---
    public static int getPendingLogsCount(ServletContext context) {
        int count = 0;
        
        try (Connection conn = DBConnection.getOJTDerbyConnection(context)) {
            if (conn == null) return 0;

            String sql = "SELECT COUNT(*) FROM APP.ACTIVITY_SUBMISSIONS WHERE STATUS = 'Pending'";
            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    count = rs.getInt(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return count;
    }

    // --- HELPER: MAP RESULTSET TO USER OBJECT ---
    private static User mapResultSetToUser(ResultSet rs, String role) throws SQLException {
        User u = new User();
        
        // Handle different ID column names between ADMIN and INTERN tables
        try {
            u.setId(rs.getInt("INTERN_ID"));
        } catch (SQLException e) {
            u.setId(rs.getInt("ADMIN_ID"));
        }
        
        u.setFirstName(rs.getString("FIRST_NAME"));
        u.setLastName(rs.getString("LAST_NAME"));
        u.setEmail(rs.getString("EMAIL"));
        u.setRole(role);
        
        // Optional fields found only in the INTERN table
        try {
            u.setUniversity(rs.getString("UNIVERSITY"));
            u.setOffice(rs.getString("OFFICE"));
        } catch (SQLException e) {
            // Skip if columns don't exist (e.g., when mapping an Admin)
        }
        
        return u;
    }
}