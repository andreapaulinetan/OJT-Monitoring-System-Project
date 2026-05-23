<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.io.*, java.util.*, model.*" %>
<%@ page import="util.TabSessionHelper" %>
<%
    // Disable caching for AJAX responses
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String tabId = TabSessionHelper.getTabId(request);
    User user = TabSessionHelper.getUser(session, tabId);

    if (user == null) {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        out.print("{\"error\":\"Unauthorized. Session expired.\"}");
        return;
    }

    String method = request.getMethod();

    // Helper function to escape JSON characters
    class JsonUtil {
        String escape(String s) {
            if (s == null) return "";
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < s.length(); i++) {
                char ch = s.charAt(i);
                switch (ch) {
                    case '"': sb.append("\\\""); break;
                    case '\\': sb.append("\\\\"); break;
                    case '\b': sb.append("\\b"); break;
                    case '\f': sb.append("\\f"); break;
                    case '\n': sb.append("\\n"); break;
                    case '\r': sb.append("\\r"); break;
                    case '\t': sb.append("\\t"); break;
                    default:
                        if (ch < ' ') {
                            String t = "000" + Integer.toHexString(ch);
                            sb.append("\\u").append(t.substring(t.length() - 4));
                        } else {
                            sb.append(ch);
                        }
                }
            }
            return sb.toString();
        }
    }
    JsonUtil ju = new JsonUtil();

    if ("POST".equalsIgnoreCase(method)) {
        // Only Admin can add or delete announcements
        if (!"Admin".equalsIgnoreCase(user.getRole())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print("{\"error\":\"Forbidden. Admins only.\"}");
            return;
        }

        String action = request.getParameter("action");
        if ("add".equalsIgnoreCase(action)) {
            String title = request.getParameter("title");
            String content = request.getParameter("content");
            String targetType = request.getParameter("targetType");
            String targetValue = request.getParameter("targetValue");

            if (title == null || title.trim().isEmpty() || content == null || content.trim().isEmpty() || targetType == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Missing required fields.\"}");
                return;
            }

            Announcement ann = new Announcement();
            ann.setTitle(title.trim());
            ann.setContent(content.trim());
            ann.setTargetType(targetType.trim());
            ann.setTargetValue(targetValue != null ? targetValue.trim() : "");
            ann.setSenderId(user.getId());
            ann.setSenderName(user.getFirstName() + " " + user.getLastName());

            boolean success = UserDAO.addAnnouncement(ann, getServletContext());
            if (success) {
                out.print("{\"success\":true}");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                out.print("{\"error\":\"Failed to save announcement inside database.\"}");
            }
        } else if ("delete".equalsIgnoreCase(action)) {
            String idStr = request.getParameter("id");
            if (idStr == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Missing announcement ID.\"}");
                return;
            }
            try {
                int id = Integer.parseInt(idStr);
                boolean success = UserDAO.deleteAnnouncement(id, getServletContext());
                if (success) {
                    out.print("{\"success\":true}");
                } else {
                    response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                    out.print("{\"error\":\"Failed to delete announcement.\"}");
                }
            } catch (NumberFormatException e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Invalid ID format.\"}");
            }
        } else {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Unknown action.\"}");
        }
    } else {
        // GET request -> List announcements
        List<Announcement> list;
        if ("Admin".equalsIgnoreCase(user.getRole())) {
            list = UserDAO.getAllAnnouncements(getServletContext());
        } else {
            list = UserDAO.getAnnouncementsForIntern(user.getOffice(), user.getRole(), user.getCity(), getServletContext());
        }

        StringBuilder sb = new StringBuilder();
        sb.append("[");
        for (int i = 0; i < list.size(); i++) {
            Announcement ann = list.get(i);
            sb.append("{");
            sb.append("\"id\":").append(ann.getId()).append(",");
            sb.append("\"title\":\"").append(ju.escape(ann.getTitle())).append("\",");
            sb.append("\"content\":\"").append(ju.escape(ann.getContent())).append("\",");
            sb.append("\"targetType\":\"").append(ju.escape(ann.getTargetType())).append("\",");
            sb.append("\"targetValue\":\"").append(ju.escape(ann.getTargetValue())).append("\",");
            sb.append("\"createdAt\":\"").append(ann.getCreatedAt() != null ? ann.getCreatedAt().toString() : "").append("\",");
            sb.append("\"senderId\":\"").append(ju.escape(ann.getSenderId())).append("\",");
            sb.append("\"senderName\":\"").append(ju.escape(ann.getSenderName())).append("\"");
            sb.append("}");
            if (i < list.size() - 1) {
                sb.append(",");
            }
        }
        sb.append("]");
        out.print(sb.toString());
    }
%>
