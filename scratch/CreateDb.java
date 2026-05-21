package scratch;

import java.io.BufferedReader;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class CreateDb {
    public static void main(String[] args) {
        System.out.println("=== Proactive MySQL Database Initialization ===");
        
        String mysqlUrl = "jdbc:mysql://localhost:3306/?zeroDateTimeBehavior=CONVERT_TO_NULL&useSSL=false&allowPublicKeyRetrieval=true";
        String dbName = "ojt_monitoringdb";
        String scriptPath = "database/ojt_monitoringdb.sql";
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("Connecting to MySQL server at " + mysqlUrl + "...");
            try (Connection conn = DriverManager.getConnection(mysqlUrl, "root", "")) {
                System.out.println("SUCCESS: Connected to MySQL server.");
                
                try (Statement stmt = conn.createStatement()) {
                    System.out.println("Creating database " + dbName + " (if not exists)...");
                    stmt.executeUpdate("CREATE DATABASE IF NOT EXISTS " + dbName);
                    System.out.println("SUCCESS: Database " + dbName + " verified/created.");
                }
            }
            
            String specificDbUrl = "jdbc:mysql://localhost:3306/" + dbName + "?zeroDateTimeBehavior=CONVERT_TO_NULL&useSSL=false&allowPublicKeyRetrieval=true";
            System.out.println("\nConnecting specifically to database at " + specificDbUrl + "...");
            try (Connection conn = DriverManager.getConnection(specificDbUrl, "root", "")) {
                System.out.println("SUCCESS: Connected to " + dbName + ".");
                
                System.out.println("Executing schema initialization script from: " + scriptPath);
                StringBuilder sqlBuilder = new StringBuilder();
                try (BufferedReader br = new BufferedReader(new FileReader(scriptPath))) {
                    String line;
                    while ((line = br.readLine()) != null) {
                        // Skip empty lines and single-line comments
                        if (line.trim().isEmpty() || line.trim().startsWith("--") || line.trim().startsWith("/*")) {
                            continue;
                        }
                        sqlBuilder.append(line).append("\n");
                    }
                }
                
                // Split statements by semicolon
                // A simple split by ";" is usually fine for this schema script
                String[] statements = sqlBuilder.toString().split(";");
                int successCount = 0;
                try (Statement stmt = conn.createStatement()) {
                    for (String sql : statements) {
                        String trimmed = sql.trim();
                        if (!trimmed.isEmpty()) {
                            stmt.execute(trimmed);
                            successCount++;
                        }
                    }
                }
                System.out.println("SUCCESS: Executed " + successCount + " SQL statements successfully. Database is fully initialized and seeded!");
            }
        } catch (Exception e) {
            System.err.println("FAILURE: Error initializing MySQL database.");
            e.printStackTrace();
        }
    }
}
