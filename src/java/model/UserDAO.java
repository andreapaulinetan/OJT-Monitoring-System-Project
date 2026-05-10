package model;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletContext;
import util.DBConnection;

/**
 * Member 1: Data Access Object
 * Handles all database interactions for the Authentication and Dashboard modules.
 */
public class UserDAO {

    // --- 1. VALIDATE USER (For Login) ---
    public static User validateUser(String email, String hashedPassword, ServletContext context) {
        User user = null;
        Connection conn = DBConnection.getDerbyConnection(context);

        if (conn == null) return null;

        try {
            // Check ADMIN Table
            String adminSql = "SELECT * FROM ADMIN WHERE EMAIL = ? AND PASSWORD = ?";
            PreparedStatement psAdmin = conn.prepareStatement(adminSql);
            psAdmin.setString(1, email);
            psAdmin.setString(2, hashedPassword);
            ResultSet rsAdmin = psAdmin.executeQuery();

            if (rsAdmin.next()) {
                user = mapResultSetToUser(rsAdmin, "Admin");
            } else {
                // Check INTERN Table
                String internSql = "SELECT * FROM INTERN WHERE EMAIL = ? AND PASSWORD = ?";
                PreparedStatement psIntern = conn.prepareStatement(internSql);
                psIntern.setString(1, email);
                psIntern.setString(2, hashedPassword);
                ResultSet rsIntern = psIntern.executeQuery();

                if (rsIntern.next()) {
                    // Use the specific role from the DB (e.g., 'be', 'fe')
                    user = mapResultSetToUser(rsIntern, rsIntern.getString("ROLE_CODE"));
                }
                rsIntern.close();
                psIntern.close();
            }
            rsAdmin.close();
            psAdmin.close();
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return user;
    }

    // --- 2. GET ALL INTERNS (For Master List) ---
    public static List<User> getAllInterns(ServletContext context) {
        List<User> list = new ArrayList<>();
        Connection conn = DBConnection.getDerbyConnection(context);
        
        if (conn == null) return list;

        try {
            String sql = "SELECT * FROM INTERN ORDER BY LAST_NAME ASC";
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                list.add(mapResultSetToUser(rs, rs.getString("ROLE_CODE")));
            }
            
            rs.close();
            ps.close();
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Helper method to map ResultSet columns to User object fields.
     * This fixes the "getFirstName" error by ensuring all fields are set.
     */
    private static User mapResultSetToUser(ResultSet rs, String role) throws SQLException {
        User u = new User();
        // Check if we are in Admin or Intern table to get the right ID column
        try {
            u.setId(rs.getInt("INTERN_ID"));
        } catch (SQLException e) {
            u.setId(rs.getInt("ADMIN_ID"));
        }
        
        u.setFirstName(rs.getString("FIRST_NAME"));
        u.setLastName(rs.getString("LAST_NAME"));
        u.setEmail(rs.getString("EMAIL"));
        u.setRole(role);
        
        // Optional fields (only in Intern table)
        try {
            u.setUniversity(rs.getString("UNIVERSITY"));
            u.setOffice(rs.getString("OFFICE"));
        } catch (SQLException e) {
            // These don't exist in Admin table, just skip
        }
        
        return u;
    }
}