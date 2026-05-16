package controller;

import java.io.IOException;
import java.net.URLEncoder;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import model.User;
import model.UserDAO;

@WebServlet(name = "LoginServlet", urlPatterns = {"/LoginServlet"})
public class LoginServlet extends HttpServlet {

    private static final int MAX_ATTEMPTS = 3;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // If someone tries to access the servlet via URL, just send them to login page
        response.sendRedirect("login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(true);
        
        // 1. Retrieve and Normalize parameters
        String emailReq = request.getParameter("username");
        String passReq = request.getParameter("password");
        String captchaReq = request.getParameter("captcha");

        emailReq = (emailReq == null) ? "" : emailReq.trim().toLowerCase();
        passReq = (passReq == null) ? "" : passReq.trim();

        // 2. Basic Validation
        if (emailReq.isEmpty() || passReq.isEmpty()) {
            response.sendRedirect("login.jsp?err=empty");
            return;
        }

        // 3. CAPTCHA Validation & Retry Logic
        String captchaTarget = (String) session.getAttribute("captcha");
        Integer captchaFails = (Integer) session.getAttribute("captcha_retries");
        if (captchaFails == null) captchaFails = 0;

        if (captchaReq == null || !captchaReq.equalsIgnoreCase(captchaTarget)) {
            captchaFails++;
            session.setAttribute("captcha_retries", captchaFails);
            
            if (captchaFails >= MAX_ATTEMPTS) {
                triggerTotalLockout(response, session);
                return;
            }
            response.sendRedirect("login.jsp?err=1&attemptsLeft=" + (MAX_ATTEMPTS - captchaFails) + "&lastUser=" + URLEncoder.encode(emailReq, "UTF-8"));
            return;
        }
        
        // Reset captcha retries on success
        session.setAttribute("captcha_retries", 0);

        // 4. Database Authentication
        Integer loginRetries = (Integer) session.getAttribute("login_retries");
        if (loginRetries == null) loginRetries = 0;

        // UserDAO checks Admin/Intern tables
        User user = UserDAO.validateUser(emailReq, passReq, getServletContext());
        
        if (user != null) {
            // SUCCESS: Reset everything and create a fresh session
            session.invalidate(); 
            HttpSession newSession = request.getSession(true);
            
            newSession.setAttribute("user", user);
            newSession.setAttribute("role", user.getRole());
            newSession.setMaxInactiveInterval(5 * 60); // 5 minute session

            // Role-Based Routing
            String role = user.getRole();
            if ("admin".equalsIgnoreCase(role)) {
                response.sendRedirect("admin.jsp");
            } else {
                // All intern roles (be, fe, qa, uiux, da) go to guest.jsp
                response.sendRedirect("guest.jsp");
            }
        } else {
            // FAILURE: Increment login retries
            loginRetries++;
            session.setAttribute("login_retries", loginRetries);
            
            if (loginRetries >= MAX_ATTEMPTS) {
                triggerTotalLockout(response, session);
            } else {
                response.sendRedirect("login.jsp?err=2&attemptsLeft=" + (MAX_ATTEMPTS - loginRetries) + "&lastUser=" + URLEncoder.encode(emailReq, "UTF-8"));
            }
        }
    }

    private void triggerTotalLockout(HttpServletResponse response, HttpSession session) throws IOException {
        long unlockTime = System.currentTimeMillis() + (5 * 60 * 1000); // 5 minutes from now
        session.invalidate();
        response.sendRedirect("login.jsp?status=locked&until=" + unlockTime);
    }
}