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
        // We use an allow-list approach instead of insecure .contains()
        boolean isStaticResource = lowerURI.endsWith(".css") || 
                                   lowerURI.endsWith(".js") || 
                                   lowerURI.endsWith(".png") || 
                                   lowerURI.endsWith(".jpg") || 
                                   lowerURI.endsWith(".jpeg") || 
                                   lowerURI.endsWith(".gif") || 
                                   lowerURI.endsWith(".ico") ||
                                   lowerURI.startsWith(contextPath.toLowerCase() + "/css/") ||
                                   lowerURI.startsWith(contextPath.toLowerCase() + "/images/") ||
                                   lowerURI.startsWith(contextPath.toLowerCase() + "/fontawesome/");

        // 2. Identify Public Pages
        boolean loggedIn = (session != null && session.getAttribute("user") != null);
        boolean isLoginPage = lowerURI.endsWith("login.jsp");
        boolean isLoginServlet = lowerURI.endsWith("loginservlet");
        boolean isCaptcha = lowerURI.endsWith("captchaservlet");
        
        // Root path check (e.g., just visiting http://localhost:8080/Project/)
        boolean isRoot = lowerURI.equals(contextPath.toLowerCase() + "/") || 
                         lowerURI.equals(contextPath.toLowerCase());

        // 3. THE SECURITY LOGIC
        if (loggedIn || isStaticResource || isLoginPage || isLoginServlet || isCaptcha || isRoot) {
            // Add headers to prevent CSS caching issues during development
            if (isStaticResource) {
                res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
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