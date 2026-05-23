package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import model.User;
import model.UserDAO;

@WebServlet("/DeleteInternServlet")
public class DeleteInternServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Security & session verification check matching your multi-tab architecture
        HttpSession session = request.getSession(false);
        String tabId = util.TabSessionHelper.getTabId(request);
        User user = (session != null && tabId != null) ? util.TabSessionHelper.getUser(session, tabId) : null;
        
        if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
            util.ErrorLogger.logError(
                "SECURITY VIOLATION", 
                "Unauthorized attempt to delete intern profile. Active user: " + (user != null ? user.getEmail() : "anonymous") + " (Tab ID: " + tabId + ")", 
                null, 
                session, 
                getServletContext()
            );
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin privileges required.");
            return;
        }

        try {
            // Check for batch delete parameter
            String internIdsParam = request.getParameter("internIds");
            if (internIdsParam != null && !internIdsParam.trim().isEmpty()) {
                String[] ids = internIdsParam.split(",");
                int successCount = 0;
                for (String id : ids) {
                    id = id.trim();
                    if (id.isEmpty()) continue;
                    if (user != null && id.equalsIgnoreCase(user.getId())) {
                        continue; // Prevent self-deletion
                    }
                    boolean isDeleted = UserDAO.deleteIntern(id, getServletContext());
                    if (isDeleted) {
                        successCount++;
                    }
                }
                response.sendRedirect("admin.jsp?view=intern-management&status=deleted_batch&count=" + successCount + "&tabId=" + (tabId != null ? tabId : ""));
                return;
            }

            // 1. Extract intern ID parameter passed from the front-end deletion modal form
            String internId = request.getParameter("internId");
            
            // Prevent self-deletion
            if (internId != null && user != null && internId.trim().equalsIgnoreCase(user.getId())) {
                util.ErrorLogger.logError(
                    "SECURITY VIOLATION", 
                    "Blocked attempt by admin to delete their own account: " + user.getEmail(), 
                    null, 
                    session, 
                    getServletContext()
                );
                response.sendRedirect("admin.jsp?view=intern-management&err=delete_self_blocked&tabId=" + (tabId != null ? tabId : ""));
                return;
            }
            
            // Fail-safe check if parameter is null or completely empty
            if (internId == null || internId.trim().isEmpty()) {
                util.ErrorLogger.logError(
                    "MALFORMED REQUEST", 
                    "Delete operation aborted. Received an invalid or missing 'internId' parameter.", 
                    null, 
                    request.getSession(false), 
                    getServletContext()
                );
                response.sendRedirect("admin.jsp?view=intern-management&err=delete_failed&tabId=" + (tabId != null ? tabId : ""));
                return;
            }

            // 2. Fire delete transaction statement via the Data Access Object layer
            boolean isDeleted = UserDAO.deleteIntern(internId.trim(), getServletContext());
            
            // 3. Direct server execution response based on database transaction status
            if (isDeleted) {
                response.sendRedirect("admin.jsp?view=intern-management&status=deleted&tabId=" + (tabId != null ? tabId : ""));
            } else {
                util.ErrorLogger.logError(
                    "DATABASE TRANSACTION ERROR", 
                    "Failed to delete intern profile from database for ID: " + internId, 
                    null, 
                    request.getSession(false), 
                    getServletContext()
                );
                response.sendRedirect("admin.jsp?view=intern-management&err=delete_failed&tabId=" + (tabId != null ? tabId : ""));
            }
            
        } catch (Exception e) {
            util.ErrorLogger.logError(
                "SERVLET DELETE ERROR", 
                "Failed to delete intern due to input or processing exception. Intern ID: " + request.getParameter("internId"), 
                e, 
                request.getSession(false), 
                getServletContext()
            );
            e.printStackTrace();
            response.sendRedirect("admin.jsp?view=intern-management&err=delete_failed&tabId=" + (tabId != null ? tabId : ""));
        }
    }
}