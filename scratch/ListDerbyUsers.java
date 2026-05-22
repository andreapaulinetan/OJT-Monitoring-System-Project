package scratch;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class ListDerbyUsers {
    public static void main(String[] args) {
        String url = "jdbc:derby://localhost:1527/C:/Users/Sean/OneDrive/Documents/NetBeansProjects/OJT-Monitoring-System-Project/database/ojt_AuthenticationDB";
        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            System.out.println("Connecting to Apache Derby at " + url + "...");
            try (Connection conn = DriverManager.getConnection(url, "app", "app")) {
                System.out.println("SUCCESS: Connected to Apache Derby.");
                
                System.out.println("\n--- ADMIN TABLE ---");
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT * FROM ADMIN")) {
                    int cols = rs.getMetaData().getColumnCount();
                    for (int i = 1; i <= cols; i++) {
                        System.out.print(rs.getMetaData().getColumnName(i) + "\t");
                    }
                    System.out.println();
                    while (rs.next()) {
                        for (int i = 1; i <= cols; i++) {
                            System.out.print(rs.getString(i) + "\t");
                        }
                        System.out.println();
                    }
                } catch (Exception e) {
                    System.out.println("Error querying ADMIN: " + e.getMessage());
                }
                
                System.out.println("\n--- INTERN TABLE ---");
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT * FROM INTERN")) {
                    int cols = rs.getMetaData().getColumnCount();
                    for (int i = 1; i <= cols; i++) {
                        System.out.print(rs.getMetaData().getColumnName(i) + "\t");
                    }
                    System.out.println();
                    while (rs.next()) {
                        for (int i = 1; i <= cols; i++) {
                            System.out.print(rs.getString(i) + "\t");
                        }
                        System.out.println();
                    }
                } catch (Exception e) {
                    System.out.println("Error querying INTERN: " + e.getMessage());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
