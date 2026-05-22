package controller;

import java.io.IOException;
import java.net.URLEncoder;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import model.User;
import model.UserDAO;
import model.PostgreSQLDAO;

public class LoginServlet extends HttpServlet {

    private static final int MAX_ATTEMPTS = 3;


    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(true);
        String tabId = util.TabSessionHelper.getTabId(request);

        // Ensure we have a fallback tabId if none is provided (e.g. direct post)
        if (tabId == null || tabId.trim().isEmpty()) {
            tabId = "tab_login_fallback_" + System.currentTimeMillis();
        }
        
        String emailReq = request.getParameter("username");
        String passReq = request.getParameter("password");
        String captchaReq = request.getParameter("captcha");

        emailReq = (emailReq == null) ? "" : emailReq.trim().toLowerCase();
        passReq = (passReq == null) ? "" : passReq.trim();

        // 1. Validation
        if (emailReq.isEmpty() || passReq.isEmpty()) {
            util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Failed login attempt: Email or Password was left empty", null, session, getServletContext());
            response.sendRedirect("login.jsp?err=empty");
            return;
        }

        // 2. Captcha Check
        String captchaTarget = (String) util.TabSessionHelper.getAttribute(session, tabId, "captcha");
        Integer captchaFails = (Integer) util.TabSessionHelper.getAttribute(session, tabId, "captcha_retries");
        if (captchaFails == null) captchaFails = 0;

        if (captchaReq == null || !captchaReq.equalsIgnoreCase(captchaTarget)) {
            util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Failed CAPTCHA validation. Input: '" + captchaReq + "', Expected: '" + captchaTarget + "' for user: " + emailReq, null, session, getServletContext());
            captchaFails++;
            util.TabSessionHelper.setAttribute(session, tabId, "captcha_retries", captchaFails);
            if (captchaFails >= MAX_ATTEMPTS) {
                triggerTotalLockout(request, response, session, tabId);
                return;
            }
            response.sendRedirect("login.jsp?err=1&attemptsLeft=" + (MAX_ATTEMPTS - captchaFails) + "&lastUser=" + URLEncoder.encode(emailReq, "UTF-8"));
            return;
        }
        util.TabSessionHelper.setAttribute(session, tabId, "captcha_retries", 0);

        // 3. Database Authentication
        Integer loginRetries = (Integer) util.TabSessionHelper.getAttribute(session, tabId, "login_retries");
        if (loginRetries == null) loginRetries = 0;

        // UserDAO should automatically search Admin/Intern tables based on email
        User user = UserDAO.validateUser(emailReq, passReq, getServletContext());
        
        if (user != null) {
            // Re-initialize only this tab's sub-session to prevent session crossover
            util.TabSessionHelper.invalidateTab(session, tabId);
            util.TabSessionHelper.setUser(session, tabId, user);
            // Also set globally for fallback when tabId is dropped during redirects or back button
            session.setAttribute("user", user);
            session.setAttribute("role", user.getRole());
            session.setMaxInactiveInterval(15 * 60); // 15 mins inactive interval for session

            // AUTO-LOG: Record LOGIN event to PostgreSQL (DBMS 3)
            PostgreSQLDAO.insertAuditLog(
                getServletContext(),
                user.getId(),
                user.getFullName(),
                "LOGIN",
                "User logged in successfully",
                request.getRemoteAddr()
            );

            // AUTOMATIC ROUTING based on DB role, transmitting the tabId back to UI
            String role = user.getRole();
            if ("admin".equalsIgnoreCase(role)) {
                response.sendRedirect("admin.jsp?tabId=" + tabId);
            } else {
                // Redirects all intern roles (be, fe, qa, uiux, da) to guest page
                response.sendRedirect("guest.jsp?tabId=" + tabId);
            }
        } else {
            util.ErrorLogger.logError("AUTHENTICATION ERROR", "Failed login credentials validation for user: " + emailReq, null, session, getServletContext());
            loginRetries++;
            util.TabSessionHelper.setAttribute(session, tabId, "login_retries", loginRetries);
            if (loginRetries >= MAX_ATTEMPTS) {
                triggerTotalLockout(request, response, session, tabId);
            } else {
                response.sendRedirect("login.jsp?err=2&attemptsLeft=" + (MAX_ATTEMPTS - loginRetries) + "&lastUser=" + URLEncoder.encode(emailReq, "UTF-8"));
            }
        }
    }

    private void triggerTotalLockout(HttpServletRequest request, HttpServletResponse response, HttpSession session, String tabId) throws IOException {
        long unlockTime = System.currentTimeMillis() + (5 * 60 * 1000); 
        util.ErrorLogger.logError("SECURITY LOCKOUT", "User reached maximum attempts limit and triggered session lockout. User: " + request.getParameter("username"), null, session, getServletContext());
        util.TabSessionHelper.invalidateTab(session, tabId);
        response.sendRedirect("login.jsp?status=locked&until=" + unlockTime);
    }
}