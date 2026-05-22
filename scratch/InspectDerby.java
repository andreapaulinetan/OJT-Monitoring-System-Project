package scratch;

import java.sql.*;

public class InspectDerby {
    public static void main(String[] args) {
        String url = "jdbc:derby://localhost:1527/ojt_AuthenticationDB";
        String user = "app";
        String password = "app";
        
        System.out.println("Connecting to Apache Derby...");
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            System.out.println("Connected successfully!");
            
            // Query Interns
            String sql = "SELECT * FROM INTERN";
            try (PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                
                System.out.println("\n--- INTERNS IN DERBY DATABASE ---");
                ResultSetMetaData meta = rs.getMetaData();
                int colCount = meta.getColumnCount();
                for (int i = 1; i <= colCount; i++) {
                    System.out.println(meta.getColumnName(i) + "\t" + meta.getColumnTypeName(i) + "\tAutoIncrement: " + meta.isAutoIncrement(i));
                }
                System.out.println("\n------------------------------------------------");
                
                while (rs.next()) {
                    System.out.println(
                        rs.getString("INTERN_ID") + " | " +
                        rs.getString("FIRST_NAME") + " " + rs.getString("LAST_NAME") + " | " +
                        rs.getString("EMAIL") + " | " +
                        rs.getString("ROLE") + " | " +
                        rs.getString("OFFICE")
                    );
                }
            }

            // Query Admins
            String sqlAdmin = "SELECT * FROM ADMIN";
            try (PreparedStatement ps = conn.prepareStatement(sqlAdmin);
                 ResultSet rs = ps.executeQuery()) {
                
                System.out.println("\n--- ADMINS IN DERBY DATABASE ---");
                ResultSetMetaData meta = rs.getMetaData();
                int colCount = meta.getColumnCount();
                for (int i = 1; i <= colCount; i++) {
                    System.out.println(meta.getColumnName(i) + "\t" + meta.getColumnTypeName(i) + "\tAutoIncrement: " + meta.isAutoIncrement(i));
                }
                System.out.println("\n------------------------------------------------");
                
                while (rs.next()) {
                    System.out.println(
                        rs.getString("ADMIN_ID") + " | " +
                        rs.getString("FIRST_NAME") + " " + rs.getString("LAST_NAME") + " | " +
                        rs.getString("EMAIL")
                    );
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

