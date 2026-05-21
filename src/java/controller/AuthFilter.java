package controller;

import java.io.IOException;
import javax.servlet.*;
import javax.servlet.http.*;

public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        HttpSession session = req.getSession(false);

        String uri = req.getRequestURI();
        String contextPath = req.getContextPath();
        String lowerURI = uri.toLowerCase();

        // 1. Identify Static Resources (CRITICAL FIX)
        // We use .contains or .endsWith to ensure CSS/Images are always allowed
        boolean isStaticResource = lowerURI.endsWith(".css") || 
                                   lowerURI.endsWith(".js") || 
                                   lowerURI.endsWith(".png") || 
                                   lowerURI.endsWith(".jpg") || 
                                   lowerURI.endsWith(".jpeg") || 
                                   lowerURI.endsWith(".gif") || 
                                   lowerURI.endsWith(".ico") ||
                                   lowerURI.contains("/css/") || // Folders
                                   lowerURI.contains("/images/") ||
                                   lowerURI.contains("fontawesome");

        // 2. Identify Public Pages
        boolean loggedIn = (session != null && session.getAttribute("user") != null);
        boolean isLoginPage = lowerURI.endsWith("login.jsp");
        boolean isLoginServlet = lowerURI.endsWith("loginservlet");
        boolean isCaptcha = lowerURI.endsWith("captchaservlet");
        boolean isLogoutServlet = lowerURI.endsWith("logoutservlet");
        
        // Root path check (e.g., just visiting http://localhost:8080/Project/)
        boolean isRoot = lowerURI.equals(contextPath.toLowerCase() + "/") || 
                         lowerURI.equals(contextPath.toLowerCase());

        // 3. THE SECURITY LOGIC
        if (loggedIn || isStaticResource || isLoginPage || isLoginServlet || isCaptcha || isLogoutServlet || isRoot) {
            // Add headers to prevent caching issues
            if (isStaticResource) {
                res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            } else {
                // Prevent browser caching on all dynamic pages so back button triggers a session re-evaluation
                res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
                res.setHeader("Pragma", "no-cache");
                res.setDateHeader("Expires", 0);
            }
            chain.doFilter(request, response);
        } else {
            // Unauthorized access to protected JSP
            res.sendRedirect(contextPath + "/login.jsp?err=unauthorized");
        }
    }

    @Override
    public void destroy() {}
}