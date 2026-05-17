package controller;

import java.io.IOException;
import java.net.URLEncoder;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import model.User;
import model.UserDAO;

public class LoginServlet extends HttpServlet {

    private static final int MAX_ATTEMPTS = 3;


    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(true);
        
        String emailReq = request.getParameter("username");
        String passReq = request.getParameter("password");
        String captchaReq = request.getParameter("captcha");

        emailReq = (emailReq == null) ? "" : emailReq.trim().toLowerCase();
        passReq = (passReq == null) ? "" : passReq.trim();

        // 1. Validation
        if (emailReq.isEmpty() || passReq.isEmpty()) {
            response.sendRedirect("login.jsp?err=empty");
            return;
        }

        // 2. Captcha Check
        String captchaTarget = (String) session.getAttribute("captcha");
        Integer captchaFails = (Integer) session.getAttribute("captcha_retries");
        if (captchaFails == null) captchaFails = 0;

        if (captchaReq == null || !captchaReq.equalsIgnoreCase(captchaTarget)) {
            captchaFails++;
            session.setAttribute("captcha_retries", captchaFails);
            if (captchaFails >= MAX_ATTEMPTS) {
                triggerTotalLockout(request, response, session);
                return;
            }
            response.sendRedirect("login.jsp?err=1&attemptsLeft=" + (MAX_ATTEMPTS - captchaFails) + "&lastUser=" + URLEncoder.encode(emailReq, "UTF-8"));
            return;
        }
        session.setAttribute("captcha_retries", 0);

        // 3. Database Authentication
        Integer loginRetries = (Integer) session.getAttribute("login_retries");
        if (loginRetries == null) loginRetries = 0;

        // UserDAO should automatically search Admin/Intern tables based on email
        User user = UserDAO.validateUser(emailReq, passReq, getServletContext());
        
        if (user != null) {
            session.invalidate(); 
            HttpSession newSession = request.getSession(true);
            
            newSession.setAttribute("user", user);
            newSession.setAttribute("role", user.getRole());
            newSession.setMaxInactiveInterval(5 * 60);

            // AUTOMATIC ROUTING based on DB role
            String role = user.getRole();
            if ("admin".equalsIgnoreCase(role)) {
                response.sendRedirect("admin.jsp");
            } else {
                // Redirects all intern roles (be, fe, qa, uiux, da) to guest page
                response.sendRedirect("guest.jsp");
            }
        } else {
            loginRetries++;
            session.setAttribute("login_retries", loginRetries);
            if (loginRetries >= MAX_ATTEMPTS) {
                triggerTotalLockout(request, response, session);
            } else {
                response.sendRedirect("login.jsp?err=2&attemptsLeft=" + (MAX_ATTEMPTS - loginRetries) + "&lastUser=" + URLEncoder.encode(emailReq, "UTF-8"));
            }
        }
    }

    private void triggerTotalLockout(HttpServletRequest request, HttpServletResponse response, HttpSession session) throws IOException {
        long unlockTime = System.currentTimeMillis() + (5 * 60 * 1000); 
        session.invalidate();
        response.sendRedirect("login.jsp?status=locked&until=" + unlockTime);
    }
}