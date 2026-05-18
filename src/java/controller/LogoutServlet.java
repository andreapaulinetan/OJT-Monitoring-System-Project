package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.PostgreSQLDAO;
import model.User;

public class LogoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // 1. Get the current session
        HttpSession session = request.getSession(false);
        
        if (session != null) {
            // 2. Capture user info BEFORE invalidation for audit logging
            User user = (User) session.getAttribute("user");
            
            if (user != null) {
                // AUTO-LOG: Record LOGOUT event to PostgreSQL (DBMS 3)
                PostgreSQLDAO.insertAuditLog(
                    getServletContext(),
                    user.getId(),
                    user.getFullName(),
                    "LOGOUT",
                    "User session ended",
                    request.getRemoteAddr()
                );
            }
            
            // 3. Clear all data and destroy the session
            session.invalidate();
        }
        
        // 4. Redirect to login page with a "logged out" message
        response.sendRedirect("login.jsp?msg=loggedout");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}