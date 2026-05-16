package model;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletContext;
import util.DBConnection;

public class UserDAO {

/**
     * VALIDATE USER: Checks both Admin and Intern tables.
     */
    public static User validateUser(String email, String hashedPassword, ServletContext context) {
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            if (conn == null) return null;

            // 1. Check ADMIN Table
            String adminSql = "SELECT * FROM ADMIN WHERE EMAIL = ? AND PASSWORD = ?";
            try (PreparedStatement ps = conn.prepareStatement(adminSql)) {
                ps.setString(1, email);
                ps.setString(2, hashedPassword);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return mapResultSetToUser(rs, "Admin", context);
                    }
                }
            }

            // 2. Check INTERN Table - Note: Using rs.getString("ROLE") here
            String internSql = "SELECT * FROM INTERN WHERE EMAIL = ? AND PASSWORD = ?";
            try (PreparedStatement ps = conn.prepareStatement(internSql)) {
                ps.setString(1, email);
                ps.setString(2, hashedPassword);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        // Retrieve the "ROLE" column instead of "ROLE_CODE"
                        return mapResultSetToUser(rs, rs.getString("ROLE"), context);
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * GET ALL INTERNS: Fetches all interns and attaches their OJT status.
     */
public static List<User> getAllInterns(ServletContext context) {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM INTERN";
        
        try (Connection conn = DBConnection.getDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                // CHANGED: Pass rs.getString("ROLE") to the mapping helper
                User u = mapResultSetToUser(rs, rs.getString("ROLE"), context);
                list.add(u);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * GET INDIVIDUAL STATUS: Fetches status from the separate OJT database.
     */
    public static String getIndividualStatus(int userId, ServletContext context) {
        String status = "No Log"; 
        try (Connection conn = DBConnection.getOJTDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement("SELECT STATUS FROM APP.ACTIVITY_SUBMISSIONS WHERE USER_ID = ?")) {
            
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    status = rs.getString("STATUS");
                }
            }
        } catch (Exception e) {
            // Log error but don't crash; return default "No Log"
            System.err.println("Error fetching status for User ID " + userId + ": " + e.getMessage());
        }
        return status;
    }

    /**
     * GET PENDING LOGS COUNT: For dashboard statistics.
     */
    public static int getPendingLogsCount(ServletContext context) {
        int count = 0;
        try (Connection conn = DBConnection.getOJTDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM APP.ACTIVITY_SUBMISSIONS WHERE STATUS = 'Pending'");
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return count;
    }

    /**
     * HELPER METHOD: Centralized mapping logic. 
     * Ensures all fields (including Role) are set regardless of which query is called.
     */
    /**
     * HELPER METHOD: Centralized mapping logic.
     */
    private static User mapResultSetToUser(ResultSet rs, String role, ServletContext context) throws SQLException {
        User u = new User();
        
        int id;
        try {
            id = rs.getInt("INTERN_ID");
        } catch (SQLException e) {
            id = rs.getInt("ADMIN_ID");
        }
        
        u.setId(id);
        u.setFirstName(rs.getString("FIRST_NAME"));
        u.setLastName(rs.getString("LAST_NAME"));
        u.setEmail(rs.getString("EMAIL"));
        u.setPassword(rs.getString("PASSWORD"));
        
        // This is what the JSP uses for <%= u.getRole() %>
        u.setRole(role); 
        
        try {
            u.setUniversity(rs.getString("UNIVERSITY"));
            u.setOffice(rs.getString("OFFICE"));
            
            // We still store the Code if you need it for logic elsewhere, 
            // but 'role' is now the full name.
            u.setRoleCode(rs.getString("ROLE_CODE"));
            
            u.setLogStatus(getIndividualStatus(id, context));
        } catch (SQLException e) {
            // Ignored for Admin table
        }
        
        return u;
    }
}