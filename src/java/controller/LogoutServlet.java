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
        try {
            // 1. Get the current session
             HttpSession session = request.getSession(false);
             String tabId = util.TabSessionHelper.getTabId(request);
             
             if (session != null && tabId != null) {
                 // 2. Capture user info BEFORE invalidation for audit logging
                 User user = util.TabSessionHelper.getUser(session, tabId);
                 
                 if (user != null) {
                     // AUTO-LOG: Record LOGOUT event to PostgreSQL (DBMS 3)
                     PostgreSQLDAO.insertAuditLog(
                         getServletContext(),
                         user.getId(),
                         user.getFullName(),
                         "LOGOUT",
                         "User session ended (Tab ID: " + tabId + ")",
                         request.getRemoteAddr()
                     );
                 }
                 
                 // 3. Clear only this tab's session data
                 util.TabSessionHelper.invalidateTab(session, tabId);
             }
             
             // 4. Redirect to login page with a "logged out" message
             response.sendRedirect("login.jsp?msg=loggedout");
        } catch (Exception e) {
            util.ErrorLogger.logError("SERVLET ERROR", "Failed logout processing", e, request.getSession(false), getServletContext());
            if (e instanceof IOException) {
                throw (IOException) e;
            } else {
                throw new ServletException(e);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}