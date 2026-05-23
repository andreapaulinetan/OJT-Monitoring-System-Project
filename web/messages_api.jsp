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

    // Helper class for manual JSON serialization
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
        String action = request.getParameter("action");
        if ("send".equalsIgnoreCase(action)) {
            String receiverId = request.getParameter("receiverId");
            String messageText = request.getParameter("messageText");

            if (receiverId == null || receiverId.trim().isEmpty() || messageText == null || messageText.trim().isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Missing receiver or message text.\"}");
                return;
            }

            String prefSelfId = ("Admin".equalsIgnoreCase(user.getRole()) ? "ADM_" : "INT_") + user.getId();
            Message msg = new Message();
            msg.setSenderId(prefSelfId);
            msg.setReceiverId(receiverId.trim());
            msg.setMessageText(messageText.trim());

            boolean success = UserDAO.sendMessage(msg, getServletContext());
            if (success) {
                out.print("{\"success\":true}");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                out.print("{\"error\":\"Failed to insert message into database.\"}");
            }
        } else if ("read".equalsIgnoreCase(action)) {
            String contactId = request.getParameter("contactId");
            if (contactId == null || contactId.trim().isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Missing contact ID.\"}");
                return;
            }
            String prefSelfId = ("Admin".equalsIgnoreCase(user.getRole()) ? "ADM_" : "INT_") + user.getId();
            // Mark all messages sent from contactId to current user as read
            UserDAO.markMessagesAsRead(contactId.trim(), prefSelfId, getServletContext());
            out.print("{\"success\":true}");
        } else {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Unknown action.\"}");
        }
    } else {
        // GET request
        String action = request.getParameter("action");
        if ("contacts".equalsIgnoreCase(action)) {
            // Fetch contacts list, unread counts, and last message times
            String prefSelfId = ("Admin".equalsIgnoreCase(user.getRole()) ? "ADM_" : "INT_") + user.getId();
            Map<String, Integer> unreadCounts = UserDAO.getUnreadCounts(prefSelfId, getServletContext());
            Map<String, java.sql.Timestamp> lastTimes = UserDAO.getLastMessageTimes(prefSelfId, getServletContext());
            List<User> contacts = new ArrayList<User>();

            if ("Admin".equalsIgnoreCase(user.getRole())) {
                // Admin can contact Interns and other Admins
                List<User> interns = UserDAO.getAllInterns(getServletContext());
                if (interns != null) contacts.addAll(interns);

                List<User> admins = UserDAO.getAllAdmins(getServletContext());
                if (admins != null) {
                    for (User admin : admins) {
                        if (!admin.getId().equals(user.getId())) {
                            contacts.add(admin);
                        }
                    }
                }
            } else {
                // Intern can only contact Admins
                List<User> admins = UserDAO.getAllAdmins(getServletContext());
                if (admins != null) contacts.addAll(admins);
            }

            StringBuilder sb = new StringBuilder();
            sb.append("[");
            for (int i = 0; i < contacts.size(); i++) {
                User c = contacts.get(i);
                String prefContactId = ("Admin".equalsIgnoreCase(c.getRole()) ? "ADM_" : "INT_") + c.getId();
                int unread = unreadCounts.containsKey(prefContactId) ? unreadCounts.get(prefContactId) : 0;
                String fullName = c.getFirstName() + " " + c.getLastName();
                String role = c.getRole();
                String office = c.getOffice() != null ? c.getOffice() : "Main Administration Office";
                java.sql.Timestamp lastTime = lastTimes.get(prefContactId);
                String lastTimeStr = lastTime != null ? lastTime.toString() : "";

                sb.append("{");
                sb.append("\"id\":\"").append(ju.escape(prefContactId)).append("\",");
                sb.append("\"name\":\"").append(ju.escape(fullName)).append("\",");
                sb.append("\"role\":\"").append(ju.escape(role)).append("\",");
                sb.append("\"office\":\"").append(ju.escape(office)).append("\",");
                sb.append("\"avatarPath\":\"").append(ju.escape(c.getAvatarPath() != null ? c.getAvatarPath() : "")).append("\",");
                sb.append("\"unreadCount\":").append(unread).append(",");
                sb.append("\"lastMessageTime\":\"").append(ju.escape(lastTimeStr)).append("\"");
                sb.append("}");

                if (i < contacts.size() - 1) {
                    sb.append(",");
                }
            }
            sb.append("]");
            out.print(sb.toString());

        } else if ("history".equalsIgnoreCase(action)) {
            String contactId = request.getParameter("contactId");
            if (contactId == null || contactId.trim().isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\":\"Missing contact ID.\"}");
                return;
            }

            String prefSelfId = ("Admin".equalsIgnoreCase(user.getRole()) ? "ADM_" : "INT_") + user.getId();
            // Mark these messages as read since the history is being loaded
            UserDAO.markMessagesAsRead(contactId.trim(), prefSelfId, getServletContext());

            List<Message> history = UserDAO.getMessageHistory(prefSelfId, contactId.trim(), getServletContext());
            StringBuilder sb = new StringBuilder();
            sb.append("[");
            for (int i = 0; i < history.size(); i++) {
                Message m = history.get(i);
                sb.append("{");
                sb.append("\"id\":").append(m.getId()).append(",");
                sb.append("\"senderId\":\"").append(ju.escape(m.getSenderId())).append("\",");
                sb.append("\"receiverId\":\"").append(ju.escape(m.getReceiverId())).append("\",");
                sb.append("\"messageText\":\"").append(ju.escape(m.getMessageText())).append("\",");
                sb.append("\"createdAt\":\"").append(m.getCreatedAt() != null ? m.getCreatedAt().toString() : "").append("\",");
                sb.append("\"isRead\":").append(m.isIsRead());
                sb.append("}");

                if (i < history.size() - 1) {
                    sb.append(",");
                }
            }
            sb.append("]");
            out.print(sb.toString());
        } else {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Unknown action.\"}");
        }
    }
%>
