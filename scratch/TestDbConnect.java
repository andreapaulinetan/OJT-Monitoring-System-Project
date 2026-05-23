package scratch;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class TestDbConnect {
    public static void main(String[] args) {
        System.out.println("=== Standalone Database Connection Diagnostics ===");
        
        // Test MySQL
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String url = "jdbc:mysql://localhost:3306/ojt_monitoringdb?zeroDateTimeBehavior=CONVERT_TO_NULL&useSSL=false&allowPublicKeyRetrieval=true";
            System.out.println("Connecting to MySQL at " + url + "...");
            try (Connection conn = DriverManager.getConnection(url, "root", "")) {
                System.out.println("SUCCESS: Connected to MySQL successfully!");
                System.out.println("Database Product Name: " + conn.getMetaData().getDatabaseProductName());
                System.out.println("Database Product Version: " + conn.getMetaData().getDatabaseProductVersion());
                
                // Query table activity_submissions
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM activity_submissions")) {
                    if (rs.next()) {
                        System.out.println("activity_submissions row count: " + rs.getInt(1));
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("FAILURE MySQL: " + e.getMessage());
            e.printStackTrace();
        }
        
        // Test Derby
        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            String url = "jdbc:derby://localhost:1527/ojt_AuthenticationDB";
            System.out.println("\nConnecting to Apache Derby at " + url + "...");
            try (Connection conn = DriverManager.getConnection(url, "app", "app")) {
                System.out.println("SUCCESS: Connected to Apache Derby successfully!");
                System.out.println("Database Product Name: " + conn.getMetaData().getDatabaseProductName());
                System.out.println("Database Product Version: " + conn.getMetaData().getDatabaseProductVersion());
            }
        } catch (Exception e) {
            System.out.println("FAILURE Derby: " + e.getMessage());
            e.printStackTrace();
        }

        // Test PostgreSQL
        try {
            Class.forName("org.postgresql.Driver");
            String url = "jdbc:postgresql://localhost:5432/ojt_auditdb";
            System.out.println("\nConnecting to PostgreSQL at " + url + "...");
            try (Connection conn = DriverManager.getConnection(url, "postgres", "app")) {
                System.out.println("SUCCESS: Connected to PostgreSQL successfully!");
                System.out.println("Database Product Name: " + conn.getMetaData().getDatabaseProductName());
                System.out.println("Database Product Version: " + conn.getMetaData().getDatabaseProductVersion());
            }
        } catch (Exception e) {
            System.out.println("FAILURE PostgreSQL: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
