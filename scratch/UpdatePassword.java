package scratch;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;

public class UpdatePassword {
    private static final String[] URLS = {
        "jdbc:derby://localhost:1527/ojt_AuthenticationDB",
        "jdbc:derby://localhost:1527/C:/Users/andre/OneDrive/Documents/NetBeansProjects/FinalProject_2CSD_DelaCruz_Hernandez_Mejia_Tan/database/ojt_AuthenticationDB",
        "jdbc:derby://localhost:1527/c:/Users/andre/OneDrive/Documents/NetBeansProjects/FinalProject_2CSD_DelaCruz_Hernandez_Mejia_Tan/database/ojt_AuthenticationDB"
    };

    public static void main(String[] args) {
        String newEncryptedPwd = "enc:FUcYVLnfiwi+3gZOcYHiDQ=="; // AES encrypted "pass123"
        String targetId = "INT2026-70011";

        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            for (String url : URLS) {
                System.out.println("Connecting to database: " + url);
                try (Connection conn = DriverManager.getConnection(url, "app", "app")) {
                    String sql = "UPDATE INTERN SET PASSWORD = ? WHERE INTERN_ID = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, newEncryptedPwd);
                        ps.setString(2, targetId);
                        int rows = ps.executeUpdate();
                        System.out.println("  Updated INTERN table: " + rows + " row(s) updated.");
                    }
                    
                    String sqlApp = "UPDATE APP.INTERN SET PASSWORD = ? WHERE INTERN_ID = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlApp)) {
                        ps.setString(1, newEncryptedPwd);
                        ps.setString(2, targetId);
                        int rows = ps.executeUpdate();
                        System.out.println("  Updated APP.INTERN table: " + rows + " row(s) updated.");
                    }
                } catch (Exception e) {
                    System.out.println("  Skipping/Error: " + e.getMessage());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
