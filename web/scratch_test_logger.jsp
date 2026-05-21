<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*, util.ErrorLogger, java.text.SimpleDateFormat, java.util.Date, java.sql.SQLException" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Diagnostics: Session Error Logger Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --accent: #6366f1;
            --accent-hover: #4f46e5;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --border: #334155;
            --success: #10b981;
            --error: #f43f5e;
            --warn: #f59e0b;
        }
        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--bg-primary);
            color: var(--text-main);
            margin: 0;
            padding: 40px 20px;
            display: flex;
            justify-content: center;
        }
        .container {
            max-width: 900px;
            width: 100%;
        }
        h1 {
            font-size: 2.25rem;
            font-weight: 700;
            margin-bottom: 8px;
            background: linear-gradient(135deg, #a5b4fc, #6366f1);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .subtitle {
            color: var(--text-muted);
            margin-bottom: 30px;
            font-size: 1.1rem;
        }
        .card {
            background-color: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 24px;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
        }
        .card-title {
            font-size: 1.25rem;
            font-weight: 600;
            margin-top: 0;
            margin-bottom: 16px;
            border-bottom: 1px solid var(--border);
            padding-bottom: 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .badge {
            font-size: 0.75rem;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 9999px;
            text-transform: uppercase;
        }
        .badge-info { background: #0284c7; color: #fff; }
        .badge-success { background: var(--success); color: #fff; }
        
        .btn-group {
            display: flex;
            gap: 12px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        .btn {
            background-color: var(--accent);
            color: white;
            border: none;
            padding: 12px 20px;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            text-decoration: none;
            display: inline-block;
            font-size: 0.95rem;
        }
        .btn:hover {
            background-color: var(--accent-hover);
            transform: translateY(-1px);
        }
        .btn-secondary {
            background-color: transparent;
            border: 1px solid var(--border);
            color: var(--text-main);
        }
        .btn-secondary:hover {
            background-color: var(--border);
        }
        .console {
            background-color: #020617;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 16px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.875rem;
            overflow-x: auto;
            color: #38bdf8;
            max-height: 400px;
            white-space: pre-wrap;
        }
        .metadata-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }
        .meta-item {
            background-color: rgba(15, 23, 42, 0.4);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px;
        }
        .meta-label {
            font-size: 0.75rem;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 4px;
        }
        .meta-value {
            font-size: 0.95rem;
            font-weight: 600;
            font-family: 'JetBrains Mono', monospace;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>OJT-MS Error Logger Diagnostics</h1>
        <div class="subtitle">Real-time session-based log creation and integrity validation dashboard.</div>

        <%
            // Resolve session context details
            String sessId = session.getId();
            String logPath = System.getProperty("user.home") + File.separator + "OJT_Monitoring_System_Logs";
            File logDirFile = new File(logPath);
            File sessionLogFile = new File(logDirFile, "session_" + sessId + "_errors.log");

            String triggerType = request.getParameter("trigger");
            String logMessage = "";
            if (triggerType != null) {
                if ("input".equals(triggerType)) {
                    ErrorLogger.logError("INPUT VALIDATION ERROR", "User submitted a malformed task simulation string ('abc' instead of double value)", null, session, application);
                    logMessage = "Successfully simulated and recorded INPUT VALIDATION ERROR to session log!";
                } else if ("db".equals(triggerType)) {
                    SQLException mockEx = new SQLException("Connection timeout: Host 'localhost' is unreachable on port 1527", "08001", 40001);
                    ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed connection handshake to Apache Derby client driver context", mockEx, session, application);
                    logMessage = "Successfully simulated and recorded DATABASE TRANSACTION ERROR with mock SQLException trace!";
                } else if ("servlet".equals(triggerType)) {
                    NullPointerException mockNpe = new NullPointerException("Cannot invoke 'model.User.getRoleCode()' because 'user' is null inside SubmitTaskServlet");
                    ErrorLogger.logError("SERVLET ERROR", "Uncaught runtime exception caught in servlet post controller dispatcher", mockNpe, session, application);
                    logMessage = "Successfully simulated and recorded SERVLET ERROR with NullPointerException trace!";
                } else if ("clear".equals(triggerType)) {
                    if (sessionLogFile.exists()) {
                        sessionLogFile.delete();
                        logMessage = "Deleted session log file successfully.";
                    }
                }
            }
        %>

        <% if (!logMessage.isEmpty()) { %>
            <div class="card" style="border-color: var(--success); background-color: rgba(16, 185, 129, 0.05); margin-bottom: 24px;">
                <div style="color: var(--success); font-weight: 600; display: flex; align-items: center; gap: 8px;">
                    <span style="font-size: 1.25rem;">✔</span> <%= logMessage %>
                </div>
            </div>
        <% } %>

        <div class="card">
            <div class="card-title">
                Session Logging Context Info
                <span class="badge badge-info">Active Context</span>
            </div>
            <div class="metadata-grid">
                <div class="meta-item">
                    <div class="meta-label">Session ID</div>
                    <div class="meta-value" style="color: #38bdf8;"><%= sessId %></div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Log Directory Real Path</div>
                    <div class="meta-value" style="font-size: 0.85rem;"><%= logPath %></div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Session Log File Name</div>
                    <div class="meta-value" style="color: #fb7185;"><%= sessionLogFile.getName() %></div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Session Log Status</div>
                    <div class="meta-value" style="color: <%= sessionLogFile.exists() ? "var(--success)" : "var(--warn)" %>">
                        <%= sessionLogFile.exists() ? "CREATED & ACTIVE (" + sessionLogFile.length() + " bytes)" : "NOT YET CREATED" %>
                    </div>
                </div>
            </div>

            <div class="card-title" style="border: none; margin-bottom: 8px;">Trigger Simulated Log Events</div>
            <div class="btn-group">
                <a href="?trigger=input" class="btn">Simulate Input Error</a>
                <a href="?trigger=db" class="btn" style="background-color: var(--warn);">Simulate DB Error</a>
                <a href="?trigger=servlet" class="btn" style="background-color: var(--error);">Simulate Servlet Error</a>
                <% if (sessionLogFile.exists()) { %>
                    <a href="?trigger=clear" class="btn btn-secondary">Delete Session Log File</a>
                <% } %>
            </div>
        </div>

        <div class="card">
            <div class="card-title">
                Session Log File Reader Console (`<%= sessionLogFile.getName() %>`)
                <span class="badge badge-success">Live View</span>
            </div>
            <%
                if (sessionLogFile.exists()) {
                    BufferedReader reader = null;
                    try {
                        reader = new BufferedReader(new FileReader(sessionLogFile));
                        StringBuilder fileContent = new StringBuilder();
                        String line;
                        while ((line = reader.readLine()) != null) {
                            fileContent.append(line).append("\n");
                        }
            %>
                        <div class="console"><%= fileContent.toString() %></div>
            <%
                    } catch (IOException e) {
            %>
                        <div class="console" style="color: var(--error);">Error reading file: <%= e.getMessage() %></div>
            <%
                    } finally {
                        if (reader != null) {
                            try { reader.close(); } catch(IOException ex) {}
                        }
                    }
                } else {
            %>
                <div class="console" style="color: var(--text-muted); font-style: italic;">
                    Session log file does not exist yet. Please trigger an event above to create it!
                </div>
            <%
                }
            %>
        </div>

        <div class="btn-group" style="justify-content: center; margin-top: 20px;">
            <a href="login.jsp" class="btn btn-secondary">← Back to Portal Login</a>
            <a href="scratch_test_db.jsp" class="btn btn-secondary">Go to Connection Diagnostics →</a>
        </div>
    </div>
</body>
</html>
