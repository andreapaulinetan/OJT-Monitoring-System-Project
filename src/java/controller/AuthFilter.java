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

        util.ErrorLogger.initThread(session, req.getServletContext());
        try {
            String uri = req.getRequestURI();
            String contextPath = req.getContextPath();
            String lowerURI = uri.toLowerCase();
            String tabId = util.TabSessionHelper.getTabId(req);

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
            boolean loggedIn = (session != null && tabId != null && util.TabSessionHelper.getUser(session, tabId) != null);
            boolean isLoginPage = lowerURI.endsWith("login.jsp");
            boolean isLoginServlet = lowerURI.endsWith("loginservlet");
            boolean isCaptcha = lowerURI.endsWith("captchaservlet");
            boolean isLogoutServlet = lowerURI.endsWith("logoutservlet");
            
            // Allow all custom premium error pages to be accessed publicly
            boolean isErrorPage = lowerURI.contains("error_") || lowerURI.contains("eror_") || lowerURI.contains("scratch_");
            
            // Root path check (e.g., just visiting http://localhost:8080/Project/)
            boolean isRoot = lowerURI.equals(contextPath.toLowerCase() + "/") || 
                             lowerURI.equals(contextPath.toLowerCase());

            // Verify if the requested resource actually exists in the deployment context.
            // If it doesn't, we bypass redirect security checks so that the container naturally
            // registers a 404 Page Not Found error and dispatches the customized error page.
            String servletPath = req.getServletPath();
            boolean fileExists = false;
            if (servletPath != null) {
                try {
                    java.net.URL resUrl = req.getServletContext().getResource(servletPath);
                    if (resUrl != null) {
                        fileExists = true;
                    }
                } catch (Exception e) {
                    // Fail-safe default
                }
            }
            boolean isServletMapping = lowerURI.contains("servlet");
            boolean resourceExists = fileExists || isServletMapping || isRoot || isStaticResource;

            // 3. THE SECURITY LOGIC
            if (loggedIn || isStaticResource || isLoginPage || isLoginServlet || isCaptcha || isLogoutServlet || isRoot || isErrorPage || !resourceExists) {
                // Role-Based Access Control (RBAC) Checks
                if (loggedIn && !isStaticResource) {
                    model.User loggedInUser = util.TabSessionHelper.getUser(session, tabId);
                    if (loggedInUser != null) {
                        boolean isAdminUser = "admin".equalsIgnoreCase(loggedInUser.getRole());
                        
                        // Block Interns/Guests from accessing coordinator/admin pages
                        if (lowerURI.contains("admin.jsp") && !isAdminUser) {
                            util.ErrorLogger.logError("SECURITY VIOLATION", 
                                "Unauthorized attempt to access admin.jsp by non-admin user: " + loggedInUser.getEmail() + " (Role: " + loggedInUser.getRole() + ")", 
                                null, session, req.getServletContext());
                            res.sendRedirect(contextPath + "/login.jsp?err=unauthorized");
                            return;
                        }
                        
                        // Block Admins from guest/intern pages
                        if (lowerURI.contains("guest.jsp") && isAdminUser) {
                            res.sendRedirect(contextPath + "/admin.jsp?tabId=" + tabId);
                            return;
                        }
                    }
                }

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
                // If not logged in or missing tabId, detect direct JSP or servlet access attempts
                if ((lowerURI.endsWith(".jsp") || lowerURI.contains("servlet") || lowerURI.contains("dashboard")) && !isLoginPage && !isLoginServlet && !isCaptcha && !isLogoutServlet) {
                    util.ErrorLogger.logError("UNAUTHORIZED ACCESS", 
                        "Direct URL access attempt to protected resource: " + uri + " (Tab ID: " + tabId + ") from IP: " + req.getRemoteAddr(), 
                        null, session, req.getServletContext());
                }
                // Unauthorized access to protected resource
                res.sendRedirect(contextPath + "/login.jsp?err=unauthorized");
            }
        } finally {
            util.ErrorLogger.clearThread();
        }
    }

    @Override
    public void destroy() {}
}