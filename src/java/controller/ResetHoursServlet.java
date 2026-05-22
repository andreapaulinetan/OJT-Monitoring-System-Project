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

@WebServlet("/ResetHoursServlet")
public class ResetHoursServlet extends HttpServlet {
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
                "Unauthorized attempt to reset intern simulated hours. Active user: " + (user != null ? user.getEmail() : "anonymous") + " (Tab ID: " + tabId + ")", 
                null, 
                session, 
                getServletContext()
            );
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin privileges required.");
            return;
        }

        try {
            // 1. Extract intern ID parameter passed from the front-end reset hours modal form
            String internId = request.getParameter("internId");
            
            // Fail-safe check if parameter is null or completely empty
            if (internId == null || internId.trim().isEmpty()) {
                util.ErrorLogger.logError(
                    "MALFORMED REQUEST", 
                    "Hours reset operation aborted. Received an invalid or missing 'internId' parameter.", 
                    null, 
                    request.getSession(false), 
                    getServletContext()
                );
                response.sendRedirect("admin.jsp?view=intern-management&err=hours_reset_failed&tabId=" + (tabId != null ? tabId : ""));
                return;
            }

            // 2. Fire reset hours transaction statement via the Data Access Object layer
            boolean isReset = UserDAO.setResetHoursFlag(internId.trim(), true, getServletContext());
            
            // 3. Direct server execution response based on database transaction status
            if (isReset) {
                response.sendRedirect("admin.jsp?view=intern-management&status=hours_reset&tabId=" + (tabId != null ? tabId : ""));
            } else {
                util.ErrorLogger.logError(
                    "DATABASE TRANSACTION ERROR", 
                    "Failed to update RESET_HOURS database flag for intern ID: " + internId, 
                    null, 
                    request.getSession(false), 
                    getServletContext()
                );
                response.sendRedirect("admin.jsp?view=intern-management&err=hours_reset_failed&tabId=" + (tabId != null ? tabId : ""));
            }
            
        } catch (Exception e) {
            util.ErrorLogger.logError(
                "SERVLET RESET ERROR", 
                "Failed to reset intern hours due to input or processing exception. Intern ID: " + request.getParameter("internId"), 
                e, 
                request.getSession(false), 
                getServletContext()
            );
            e.printStackTrace();
            response.sendRedirect("admin.jsp?view=intern-management&err=hours_reset_failed&tabId=" + (tabId != null ? tabId : ""));
        }
    }
}
