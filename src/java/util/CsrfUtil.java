package util;

import java.security.SecureRandom;
import java.util.Base64;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * Utility class for Cross-Site Request Forgery (CSRF) protection.
 * Implements the Synchronizer Token Pattern: a random token is stored
 * in the session and must be included in every state-changing form submission.
 */
public class CsrfUtil {

    private static final String CSRF_TOKEN_ATTR = "csrfToken";
    private static final String CSRF_PARAM_NAME = "csrfToken";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int TOKEN_BYTE_LENGTH = 32;

    private CsrfUtil() {
        // Utility class — not instantiable
    }

    /**
     * Returns the CSRF token for the current session, creating one if it
     * does not already exist.
     *
     * @param session the current HTTP session
     * @return the CSRF token string
     */
    public static String getToken(HttpSession session) {
        String token = (String) session.getAttribute(CSRF_TOKEN_ATTR);
        if (token == null) {
            token = generateToken();
            session.setAttribute(CSRF_TOKEN_ATTR, token);
        }
        return token;
    }

    /**
     * Validates that the CSRF token submitted with the request matches
     * the one stored in the session.
     *
     * @param request the HTTP request containing the submitted token
     * @param session the HTTP session containing the expected token
     * @return true if the tokens match; false otherwise
     */
    public static boolean validateToken(HttpServletRequest request, HttpSession session) {
        String sessionToken = (String) session.getAttribute(CSRF_TOKEN_ATTR);
        String requestToken = request.getParameter(CSRF_PARAM_NAME);
        if (sessionToken == null || requestToken == null) {
            return false;
        }
        return constantTimeEquals(sessionToken, requestToken);
    }

    /**
     * Returns the HTML form parameter name used to submit the CSRF token.
     */
    public static String getParameterName() {
        return CSRF_PARAM_NAME;
    }

    /**
     * Generates a new cryptographically secure random token.
     */
    private static String generateToken() {
        byte[] bytes = new byte[TOKEN_BYTE_LENGTH];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * Constant-time string comparison to prevent timing attacks.
     */
    private static boolean constantTimeEquals(String a, String b) {
        if (a.length() != b.length()) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= a.charAt(i) ^ b.charAt(i);
        }
        return result == 0;
    }
}
