package model;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletContext;
import util.DBConnection;

public class UserDAO {

    // --- 1. VALIDATE USER (Fixed compilation error) ---
    public static User validateUser(String email, String hashedPassword, ServletContext context) {
        User user = null;
        // Using getDerbyConnection for AuthDB
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

            // If not admin, check INTERN Table
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

    // --- 2. GET ALL INTERNS ---
    public static List<User> getAllInterns(ServletContext context) {
        List<User> list = new ArrayList<>();
        try (Connection conn = DBConnection.getDerbyConnection(context)) {
            String sql = "SELECT * FROM INTERN";
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                User u = new User();
                u.setId(rs.getInt("INTERN_ID"));
                u.setFirstName(rs.getString("FIRST_NAME"));
                u.setLastName(rs.getString("LAST_NAME"));
                u.setEmail(rs.getString("EMAIL"));
                u.setPassword(rs.getString("PASSWORD"));
                u.setUniversity(rs.getString("UNIVERSITY"));
                u.setRoleCode(rs.getString("ROLE_CODE"));
                u.setOffice(rs.getString("OFFICE"));
                
                // NEW: Fetch the status for this specific intern from ojtdb
                u.setLogStatus(getIndividualStatus(u.getId(), context));
                
                list.add(u);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // --- 3. GET INDIVIDUAL STATUS (New Method for the Table) ---
    public static String getIndividualStatus(int userId, ServletContext context) {
        String status = "No Log"; 
        // Connects to OJTDB
        try (Connection conn = DBConnection.getOJTDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement("SELECT STATUS FROM APP.ACTIVITY_SUBMISSIONS WHERE USER_ID = ?")) {
            
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    status = rs.getString("STATUS");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return status;
    }

    // --- 4. GET PENDING LOGS COUNT (For Pink Card) ---
    public static int getPendingLogsCount(ServletContext context) {
        int count = 0;
        try (Connection conn = DBConnection.getOJTDerbyConnection(context);
             PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM APP.ACTIVITY_SUBMISSIONS WHERE STATUS = 'Pending'")) {

            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return count;
    }

    private static User mapResultSetToUser(ResultSet rs, String role) throws SQLException {
        User u = new User();
        try {
            u.setId(rs.getInt("INTERN_ID"));
        } catch (SQLException e) {
            u.setId(rs.getInt("ADMIN_ID"));
        }
        u.setFirstName(rs.getString("FIRST_NAME"));
        u.setLastName(rs.getString("LAST_NAME"));
        u.setEmail(rs.getString("EMAIL"));
        u.setRole(role);
        try {
            u.setUniversity(rs.getString("UNIVERSITY"));
            u.setOffice(rs.getString("OFFICE"));
        } catch (SQLException e) {}
        return u;
    }
}