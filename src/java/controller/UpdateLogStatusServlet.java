package controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.User;
import util.DBConnection; // Explicitly import your utility framework package

@WebServlet("/UpdateLogStatusServlet")
public class UpdateLogStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Security & session verification check
        HttpSession session = request.getSession(false);
        
        // CSRF Token Validation
        if (session == null || !util.CsrfUtil.validateToken(request, session)) {
            util.ErrorLogger.logError("CSRF VIOLATION", "Update status attempt blocked due to invalid or missing CSRF token.", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
            return;
        }

        String tabId = util.TabSessionHelper.getTabId(request);
        User user = util.TabSessionHelper.getUser(session, tabId);
        
        if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
            util.ErrorLogger.logError("SECURITY VIOLATION", "Unauthorized attempt to update submission status. Active user: " + (user != null ? user.getEmail() : "anonymous") + " (Tab ID: " + tabId + ")", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin privileges required.");
            return;
        }

        // 1. Intercept the asynchronous parameters passed by the JavaScript fetch engine
        String submissionId = request.getParameter("submissionId");
        String status = request.getParameter("status");

        // Input guard control tracker clauses
        if (submissionId == null || status == null) {
            util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Missing parameters in UpdateLogStatusServlet. submissionId: " + submissionId + ", status: " + status, null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing parameters.");
            return;
        }

        // Validate submissionId format
        if (!util.InputValidator.isValidSubmissionId(submissionId)) {
            util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Invalid submissionId format: " + submissionId, null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid submission ID format.");
            return;
        }

        // Validate status value against whitelist
        java.util.Set<String> statusWhitelist = new java.util.HashSet<>(java.util.Arrays.asList("pending", "approved", "rejected"));
        if (!util.InputValidator.isInWhitelist(status, statusWhitelist)) {
            util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Invalid status parameter: " + status, null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid status parameter.");
            return;
        }

        // Canonicalize status
        String canonicalStatus = status.trim().substring(0, 1).toUpperCase() + status.trim().substring(1).toLowerCase();

        String sqlQuery = "UPDATE activity_submissions SET status = ? WHERE submission_id = ?";

        // 2. Utilize your existing DBConnection utility class to pull from web.xml context params
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(getServletContext())) {
            
            if (conn == null) {
                util.ErrorLogger.logError("DATABASE CONNECTION ERROR", "Failed to establish MySQL connection in UpdateLogStatusServlet", null, session, getServletContext());
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to establish a database pipeline connection context.");
                return;
            }
            
            try (PreparedStatement pstmt = conn.prepareStatement(sqlQuery)) {
                pstmt.setString(1, canonicalStatus);
                pstmt.setString(2, submissionId.trim());
                
                int rowsUpdated = pstmt.executeUpdate();
                
                if (rowsUpdated > 0) {
                    response.setStatus(HttpServletResponse.SC_OK);
                    System.out.println("SQL Synchronizer Notification: Submission #" + submissionId + " status successfully updated to " + canonicalStatus);
                } else {
                    util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to update submission status. Record submissionId '" + submissionId + "' not found.", null, session, getServletContext());
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Record entry target instance not found in row updates execution.");
                }
            }
        } catch (Exception e) {
            util.ErrorLogger.logError("SERVLET UPDATE ERROR", "Error updating submission status for submission ID: " + submissionId + " to status: " + canonicalStatus, e, session, getServletContext());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "An internal database transaction error occurred.");
        }
    }
}