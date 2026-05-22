package controller;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import model.User;
import model.UserDAO;

public class DeleteSubmissionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Security & session verification check
        HttpSession session = request.getSession(false);
        String tabId = util.TabSessionHelper.getTabId(request);
        User user = (session != null && tabId != null) ? util.TabSessionHelper.getUser(session, tabId) : null;
        
        if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
            util.ErrorLogger.logError("SECURITY VIOLATION", "Unauthorized attempt to delete submission. Active user: " + (user != null ? user.getEmail() : "anonymous") + " (Tab ID: " + tabId + ")", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin privileges required.");
            return;
        }

        try {
            // 1. Extract submission ID parameter
            String submissionId = request.getParameter("submissionId");

            // 2. Fire delete transaction statement
            boolean isDeleted = UserDAO.deleteSubmission(submissionId, getServletContext());
            
            // 3. Respond with JSON result
            if (isDeleted) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                PrintWriter out = response.getWriter();
                out.print("{\"success\":true}");
                out.flush();
            } else {
                util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to delete submission from database for ID: " + submissionId, null, request.getSession(false), getServletContext());
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to delete submission.");
            }
            
        } catch (Exception e) {
            util.ErrorLogger.logError("SERVLET DELETE ERROR", "Failed to delete submission due to input or processing exception. Submission ID: " + request.getParameter("submissionId"), e, request.getSession(false), getServletContext());
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to delete submission.");
        }
    }
}
