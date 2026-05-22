package util;

/**
 * Utility class for escaping strings to prevent Cross-Site Scripting (XSS).
 * Use escape() for HTML contexts and escapeJs() for JavaScript string contexts.
 */
public class HtmlUtil {

    private HtmlUtil() {
        // Utility class — not instantiable
    }

    /**
     * Escapes a string for safe insertion into HTML content or attributes.
     * Converts &, <, >, ", and ' to their HTML entity equivalents.
     *
     * @param input the raw string (may be null)
     * @return the escaped string, or an empty string if input is null
     */
    public static String escape(String input) {
        if (input == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder(input.length() + 16);
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            switch (c) {
                case '&':  sb.append("&amp;");  break;
                case '<':  sb.append("&lt;");   break;
                case '>':  sb.append("&gt;");   break;
                case '"':  sb.append("&quot;"); break;
                case '\'': sb.append("&#x27;"); break;
                default:   sb.append(c);        break;
            }
        }
        return sb.toString();
    }

    /**
     * Escapes a string for safe insertion into a JavaScript string literal.
     * Handles quotes, backslashes, newlines, and HTML-sensitive chars
     * to prevent both JS injection and innerHTML-based XSS.
     *
     * @param input the raw string (may be null)
     * @return the escaped string, or an empty string if input is null
     */
    public static String escapeJs(String input) {
        if (input == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder(input.length() + 16);
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '\'': sb.append("\\'");  break;
                case '"':  sb.append("\\\""); break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '\t': sb.append("\\t");  break;
                case '<':  sb.append("\\x3c"); break;
                case '>':  sb.append("\\x3e"); break;
                case '&':  sb.append("\\x26"); break;
                default:   sb.append(c);       break;
            }
        }
        return sb.toString();
    }
}
