package util;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletResponse;

public class SecurityFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization code if needed
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        if (response instanceof HttpServletResponse) {
            HttpServletResponse httpResponse = (HttpServletResponse) response;

            // Prevent Clickjacking
            httpResponse.setHeader("X-Frame-Options", "DENY");

            // Prevent MIME-sniffing
            httpResponse.setHeader("X-Content-Type-Options", "nosniff");

            // XSS Protection (Legacy but good defense in depth)
            httpResponse.setHeader("X-XSS-Protection", "1; mode=block");

            // Strict-Transport-Security (HSTS) - Tell browsers to only connect via HTTPS
            httpResponse.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload");

            // Content Security Policy (CSP)
            // Allows self, google fonts, fontawesome, ui-avatars, and cdnjs/jsdelivr for bootstrap
            httpResponse.setHeader("Content-Security-Policy", 
                "default-src 'self'; " +
                "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
                "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com https://fonts.googleapis.com; " +
                "font-src 'self' https://cdnjs.cloudflare.com https://fonts.gstatic.com; " +
                "img-src 'self' data: https://ui-avatars.com; " +
                "connect-src 'self'; " +
                "object-src 'none'; " +
                "frame-src 'none';"
            );
        }

        // Pass the request along the filter chain
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // Cleanup code if needed
    }
}
