package model;

import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletContext;
import util.DBConnection;

/**
 * Data Access Object for DBMS 3 — PostgreSQL Audit Logs.
 * Handles all CRUD operations against the audit_logs table in the auditdb database.
 */
public class PostgreSQLDAO {

    /**
     * INSERT AUDIT LOG: Records a system event (LOGIN, LOGOUT, REPORT_GENERATED).
     * Called automatically by LoginServlet, LogoutServlet, and ReportServlet.
     */
    public static boolean insertAuditLog(ServletContext ctx, String userId, String username,
                                          String action, String details, String ipAddress) {
        String sql = "INSERT INTO audit_logs (user_id, username, action, details, ip_address) VALUES (?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getPgConnection(ctx)) {
            if (conn == null) {
                System.err.println("CRITICAL: PostgreSQL connection failed in insertAuditLog!");
                return false;
            }
            
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, userId);
                ps.setString(2, username);
                ps.setString(3, action);
                ps.setString(4, details);
                ps.setString(5, ipAddress);
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to insert PostgreSQL security audit log for user " + username, e, null, ctx);
            System.err.println("Error inserting audit log: " + e.getMessage());
            return false;
        }
    }

    /**
     * GET ALL AUDIT LOGS: Fetches all audit entries ordered by most recent first.
     * Used by the Audit Trail view and the AUDITLOG PDF report.
     */
    public static List<Map<String, Object>> getAllAuditLogs(ServletContext ctx) {
        List<Map<String, Object>> logs = new ArrayList<>();
        String sql = "SELECT log_id, user_id, username, action, details, ip_address, created_at FROM audit_logs ORDER BY created_at DESC";

        try (Connection conn = DBConnection.getPgConnection(ctx)) {
            if (conn == null) {
                System.err.println("CRITICAL: PostgreSQL connection failed in getAllAuditLogs!");
                return logs;
            }

            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("log_id", rs.getInt("log_id"));
                    row.put("user_id", rs.getString("user_id"));
                    row.put("username", rs.getString("username"));
                    row.put("action", rs.getString("action"));
                    row.put("details", rs.getString("details"));
                    row.put("ip_address", rs.getString("ip_address"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    logs.add(row);
                }
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to query all PostgreSQL security audit logs", e, null, ctx);
            System.err.println("Error fetching all audit logs: " + e.getMessage());
        }
        return logs;
    }

    /**
     * GET AUDIT LOGS BY USER ID: Fetches audit entries for a specific user.
     * Used by the ADMINRECORD PDF report (shows only the logged-in admin's activity).
     */
    public static List<Map<String, Object>> getAuditLogsByUserId(ServletContext ctx, String userId) {
        List<Map<String, Object>> logs = new ArrayList<>();
        String sql = "SELECT log_id, user_id, username, action, details, ip_address, created_at FROM audit_logs WHERE user_id = ? ORDER BY created_at DESC";

        try (Connection conn = DBConnection.getPgConnection(ctx)) {
            if (conn == null) {
                System.err.println("CRITICAL: PostgreSQL connection failed in getAuditLogsByUserId!");
                return logs;
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("log_id", rs.getInt("log_id"));
                        row.put("user_id", rs.getString("user_id"));
                        row.put("username", rs.getString("username"));
                        row.put("action", rs.getString("action"));
                        row.put("details", rs.getString("details"));
                        row.put("ip_address", rs.getString("ip_address"));
                        row.put("created_at", rs.getTimestamp("created_at"));
                        logs.add(row);
                    }
                }
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to query PostgreSQL security audit logs for user ID: " + userId, e, null, ctx);
            System.err.println("Error fetching audit logs for user " + userId + ": " + e.getMessage());
        }
        return logs;
    }

    /**
     * GET AUDIT LOG COUNT: Returns total number of audit entries.
     * Used for dashboard statistics.
     */
    public static int getAuditLogCount(ServletContext ctx) {
        int count = 0;
        String sql = "SELECT COUNT(*) FROM audit_logs";

        try (Connection conn = DBConnection.getPgConnection(ctx)) {
            if (conn == null) return 0;
            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    count = rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to count PostgreSQL security audit logs", e, null, ctx);
            System.err.println("Error counting audit logs: " + e.getMessage());
        }
        return count;
    }
}
