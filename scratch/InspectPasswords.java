package scratch;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import util.CryptoUtil;

public class InspectPasswords {
    private static final String[] URLS = {
        "jdbc:derby://localhost:1527/ojt_AuthenticationDB",
        "jdbc:derby://localhost:1527/C:/Users/andre/OneDrive/Documents/NetBeansProjects/FinalProject_2CSD_DelaCruz_Hernandez_Mejia_Tan/database/ojt_AuthenticationDB"
    };

    public static void main(String[] args) {
        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            
            for (String url : URLS) {
                System.out.println("\nDATABASE: " + url);
                try (Connection conn = DriverManager.getConnection(url, "app", "app")) {
                    System.out.println("ADMINS:");
                    try (Statement stmt = conn.createStatement();
                         ResultSet rs = stmt.executeQuery("SELECT ADMIN_ID, EMAIL, PASSWORD FROM ADMIN")) {
                        while (rs.next()) {
                            String id = rs.getString("ADMIN_ID");
                            String email = rs.getString("EMAIL");
                            String pwd = rs.getString("PASSWORD");
                            String decrypted = pwd;
                            if (pwd != null && pwd.startsWith("enc:")) {
                                decrypted = CryptoUtil.decrypt(pwd.substring(4));
                            }
                            System.out.printf("  ID: %s | Email: %s | Pwd: %s | Decrypted: %s\n", id, email, pwd, decrypted);
                        }
                    }
                    
                    System.out.println("INTERNS:");
                    try (Statement stmt = conn.createStatement();
                         ResultSet rs = stmt.executeQuery("SELECT INTERN_ID, EMAIL, PASSWORD FROM INTERN")) {
                        while (rs.next()) {
                            String id = rs.getString("INTERN_ID");
                            String email = rs.getString("EMAIL");
                            String pwd = rs.getString("PASSWORD");
                            String decrypted = pwd;
                            if (pwd != null && pwd.startsWith("enc:")) {
                                decrypted = CryptoUtil.decrypt(pwd.substring(4));
                            }
                            System.out.printf("  ID: %s | Email: %s | Pwd: %s | Decrypted: %s\n", id, email, pwd, decrypted);
                        }
                    }
                } catch (Exception e) {
                    System.out.println("  Skip: " + e.getMessage());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
