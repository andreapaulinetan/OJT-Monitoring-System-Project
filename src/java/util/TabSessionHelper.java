package util;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import model.User;

/**
 * Thread-safe utility helper to maintain separate sub-sessions per browser tab
 * under a single global HTTP Session.
 */
public class TabSessionHelper {
    private static final String TAB_SESSIONS_ATTR = "TAB_SESSIONS";

    @SuppressWarnings("unchecked")
    private static Map<String, Map<String, Object>> getTabSessions(HttpSession session) {
        if (session == null) return null;
        Map<String, Map<String, Object>> tabSessions;
        synchronized (session) {
            tabSessions = (Map<String, Map<String, Object>>) session.getAttribute(TAB_SESSIONS_ATTR);
            if (tabSessions == null) {
                tabSessions = new ConcurrentHashMap<>();
                session.setAttribute(TAB_SESSIONS_ATTR, tabSessions);
            }
        }
        return tabSessions;
    }

    private static Map<String, Object> getOrCreateTabMap(HttpSession session, String tabId) {
        if (session == null || tabId == null || tabId.trim().isEmpty()) {
            return null;
        }
        Map<String, Map<String, Object>> tabSessions = getTabSessions(session);
        if (tabSessions == null) return null;
        
        return tabSessions.computeIfAbsent(tabId, k -> new ConcurrentHashMap<>());
    }

    public static Object getAttribute(HttpSession session, String tabId, String key) {
        Map<String, Object> tabMap = getOrCreateTabMap(session, tabId);
        return (tabMap != null) ? tabMap.get(key) : null;
    }

    public static void setAttribute(HttpSession session, String tabId, String key, Object value) {
        Map<String, Object> tabMap = getOrCreateTabMap(session, tabId);
        if (tabMap != null) {
            if (value == null) {
                tabMap.remove(key);
            } else {
                tabMap.put(key, value);
            }
        }
    }

    public static void removeAttribute(HttpSession session, String tabId, String key) {
        Map<String, Object> tabMap = getOrCreateTabMap(session, tabId);
        if (tabMap != null) {
            tabMap.remove(key);
        }
    }

    /**
     * Extracts the tabId parameter from query parameters, request headers, or attributes.
     */
    public static String getTabId(HttpServletRequest request) {
        if (request == null) return null;
        String tabId = request.getParameter("tabId");
        if (tabId == null || tabId.trim().isEmpty()) {
            tabId = request.getHeader("X-Tab-ID");
        }
        if (tabId == null || tabId.trim().isEmpty()) {
            tabId = (String) request.getAttribute("tabId");
        }
        return (tabId != null) ? tabId.trim() : null;
    }

    public static User getUser(HttpSession session, String tabId) {
        User user = (User) getAttribute(session, tabId, "user");
        if (user == null && session != null) {
            user = (User) session.getAttribute("user");
        }
        return user;
    }

    public static void setUser(HttpSession session, String tabId, User user) {
        setAttribute(session, tabId, "user", user);
        if (user != null) {
            setAttribute(session, tabId, "role", user.getRole());
        } else {
            removeAttribute(session, tabId, "role");
        }
    }

    public static void invalidateTab(HttpSession session, String tabId) {
        if (session == null || tabId == null) return;
        Map<String, Map<String, Object>> tabSessions = getTabSessions(session);
        if (tabSessions != null) {
            tabSessions.remove(tabId);
        }
    }
}
