package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import model.User;
import model.UserDAO;
import util.CryptoUtil;

public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // 1. Retrieve and Normalize parameters
        // .toLowerCase() ensures "Admin@gmail.com" matches "admin@gmail.com" in DB
        String emailReq = request.getParameter("username").trim().toLowerCase(); 
        String passReq = request.getParameter("password");
        String captchaReq = request.getParameter("captcha");
        
        HttpSession session = request.getSession();
        String captchaTarget = (String) session.getAttribute("captcha");

        // 2. Validate CAPTCHA
        if (captchaReq == null || !captchaReq.equalsIgnoreCase(captchaTarget)) {
            response.sendRedirect("login.jsp?err=1"); 
            return;
        }

        // 3. Password Handling
        // NOTE: If your DB has plain text, use 'passReq'. 
        // If your DB has hashed text, use 'CryptoUtil.hashPassword(passReq)'.
        String processedPass = passReq; 
        // processedPass = CryptoUtil.hashPassword(passReq); // Uncomment this for production security

        // 4. Database Validation
        // This method should check APP.ADMIN and APP.INTERN tables
        User user = UserDAO.validateUser(emailReq, processedPass, getServletContext());
        
        if (user != null) {
            // SUCCESS: Setup the Session
            session.invalidate(); // Prevent Session Fixation
            HttpSession newSession = request.getSession(true);
            
            newSession.setAttribute("user", user);
            newSession.setAttribute("role", user.getRole());

            // 5. Role-Based Redirection
            // Match the ROLE_CODE values exactly as they are in the DB
            String role = user.getRole();
            
            if ("admin".equalsIgnoreCase(role)) {
                response.sendRedirect("admin.jsp");
            } else if (role != null) {
                // If it's be, fe, qa, uiux, or da (the Intern roles)
                response.sendRedirect("guest.jsp");
            } else {
                // Fallback if role is missing
                response.sendRedirect("login.jsp?err=2");
            }
        } else {
            // FAILURE: User not found or wrong password
            response.sendRedirect("login.jsp?err=2");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        response.sendRedirect("login.jsp");
    }
}