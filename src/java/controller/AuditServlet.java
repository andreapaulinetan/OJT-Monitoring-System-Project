package controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.PostgreSQLDAO;
import model.User;

/**
 * Audit Servlet — JSON API for the Audit Trail view in admin.jsp.
 * Returns audit log entries from PostgreSQL (DBMS 3) as JSON for AJAX table rendering.
 * 
 * Endpoint: GET /AuditServlet
 * Security: Requires active admin session.
 * 
 * @author Member 3 — DBMS 3 + PDF Reports
 */
public class AuditServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Session Security Check
        HttpSession session = request.getSession(false);
        String tabId = util.TabSessionHelper.getTabId(request);
        User currentUser = (session != null && tabId != null) ? util.TabSessionHelper.getUser(session, tabId) : null;

        if (currentUser == null) {
            util.ErrorLogger.logError("UNAUTHORIZED ACCESS", "Attempted access to AuditServlet without valid session (Tab ID: " + tabId + ")", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Session expired.");
            return;
        }

        if (!"admin".equalsIgnoreCase(currentUser.getRole())) {
            util.ErrorLogger.logError("SECURITY VIOLATION", "Unauthorized non-admin access to AuditServlet. User: " + currentUser.getEmail() + " (Tab ID: " + tabId + ")", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required.");
            return;
        }

        // 2. Fetch all audit logs from PostgreSQL
        List<Map<String, Object>> logs = PostgreSQLDAO.getAllAuditLogs(getServletContext());

        // 3. Build JSON response manually (no external JSON library dependency)
        StringBuilder json = new StringBuilder();
        json.append("[");

        SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

        for (int i = 0; i < logs.size(); i++) {
            Map<String, Object> log = logs.get(i);
            Timestamp ts = (Timestamp) log.get("created_at");

            json.append("{");
            json.append("\"log_id\":").append(log.get("log_id")).append(",");
            json.append("\"user_id\":\"").append(escapeJson(String.valueOf(log.get("user_id")))).append("\",");
            json.append("\"username\":\"").append(escapeJson(String.valueOf(log.get("username")))).append("\",");
            json.append("\"action\":\"").append(escapeJson(String.valueOf(log.get("action")))).append("\",");
            json.append("\"details\":\"").append(escapeJson(String.valueOf(log.get("details")))).append("\",");
            json.append("\"ip_address\":\"").append(escapeJson(String.valueOf(log.get("ip_address")))).append("\",");
            json.append("\"created_at\":\"").append(ts != null ? fmt.format(ts) : "N/A").append("\"");
            json.append("}");

            if (i < logs.size() - 1) {
                json.append(",");
            }
        }

        json.append("]");

        // 4. Send JSON response
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        try (PrintWriter out = response.getWriter()) {
            out.print(json.toString());
            out.flush();
        }
    }

    /**
     * Escapes special characters for safe JSON string embedding.
     */
    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                     .replace("\"", "\\\"")
                     .replace("\n", "\\n")
                     .replace("\r", "\\r")
                     .replace("\t", "\\t");
    }
}
