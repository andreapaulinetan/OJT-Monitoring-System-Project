package util;

import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpSession;

public class ErrorLogger {

    private static final ThreadLocal<String> threadSessionId = new ThreadLocal<>();
    private static final ThreadLocal<ServletContext> threadServletContext = new ThreadLocal<>();

    /**
     * Initializes the thread-local variables for the current request thread.
     */
    public static void initThread(HttpSession session, ServletContext context) {
        if (session != null) {
            threadSessionId.set(session.getId());
        } else {
            threadSessionId.set(null);
        }
        threadServletContext.set(context);
    }

    /**
     * Clears the thread-local variables. Must be called in a finally block in the filter.
     */
    public static void clearThread() {
        threadSessionId.remove();
        threadServletContext.remove();
    }

    /**
     * Log an error with a default level of ERROR.
     */
    public static void logError(String message, Throwable t) {
        logError("ERROR", message, t, null, null);
    }

    /**
     * Log an error with a custom level.
     */
    public static void logError(String level, String message, Throwable t) {
        logError(level, message, t, null, null);
    }

    /**
     * Primary logging method.
     */
    public static void logError(String level, String message, Throwable t, HttpSession session, ServletContext context) {
        try {
            // 1. Resolve session ID
            String sessionId = null;
            if (session != null) {
                sessionId = session.getId();
            } else {
                sessionId = threadSessionId.get();
            }
            
            if (sessionId == null) {
                sessionId = "GLOBAL";
            }

            // 2. Resolve ServletContext
            ServletContext ctx = (context != null) ? context : threadServletContext.get();

            // 3. Resolve log directory path
            // To ensure logs are always accessible, persistent, and bypass server permissions blockages,
            // we write them directly to a dedicated folder in the User's Home directory.
            String logDirPath = System.getProperty("user.home") + File.separator + "OJT_Monitoring_System_Logs";

            File logDir = new File(logDirPath);
            if (!logDir.exists()) {
                logDir.mkdirs();
            }

            // 4. Resolve log file name
            String fileName;
            if ("GLOBAL".equals(sessionId)) {
                fileName = "system_global_errors.log";
            } else {
                fileName = "session_" + sessionId + "_errors.log";
            }

            File logFile = new File(logDir, fileName);

            // 5. Build log entry
            String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
            
            synchronized (ErrorLogger.class) {
                try (FileWriter fw = new FileWriter(logFile, true);
                     PrintWriter pw = new PrintWriter(fw)) {
                    
                    pw.println("================================================================================");
                    pw.println("Timestamp: " + timestamp);
                    pw.println("Level: [" + level + "]");
                    pw.println("Session ID: " + sessionId);
                    pw.println("Message: " + message);
                    
                    if (t != null) {
                        pw.println("Exception: " + t.toString());
                        pw.println("Stack Trace:");
                        t.printStackTrace(pw);
                    } else {
                        pw.println("Exception: None (Input / State validation failure)");
                    }
                    pw.println("================================================================================");
                    pw.println();
                }
            }
        } catch (IOException e) {
            // Fail-safe: print to console so we don't suppress the original exception
            System.err.println("CRITICAL: ErrorLogger failed to write log file: " + e.getMessage());
            if (t != null) {
                t.printStackTrace();
            }
        }
    }
}
