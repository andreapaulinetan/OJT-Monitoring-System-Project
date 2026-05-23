package scratch;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import util.CryptoUtil;

public class UpdateAllInternPasswords {
    public static void main(String[] args) {
        String rawPassword = "Pass123#";
        String encryptedPassword = CryptoUtil.hashPassword(rawPassword);
        System.out.println("Plaintext password: " + rawPassword);
        System.out.println("Encrypted representation: " + encryptedPassword);

        String url = "jdbc:derby://localhost:1527/ojt_AuthenticationDB";
        String user = "app";
        String password = "app";

        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            System.out.println("Connecting to Derby: " + url);
            try (Connection conn = DriverManager.getConnection(url, user, password)) {
                String sql = "UPDATE INTERN SET PASSWORD = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, encryptedPassword);
                    int rows = ps.executeUpdate();
                    System.out.println("Updated INTERN table: " + rows + " row(s) updated.");
                }
            }
        } catch (Exception e) {
            try {
                System.out.println("Retrying with APP prefix...");
                Class.forName("org.apache.derby.jdbc.ClientDriver");
                try (Connection conn = DriverManager.getConnection(url, user, password)) {
                    String sqlApp = "UPDATE APP.INTERN SET PASSWORD = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlApp)) {
                        ps.setString(1, encryptedPassword);
                        int rows = ps.executeUpdate();
                        System.out.println("Updated APP.INTERN table: " + rows + " row(s) updated.");
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }
}
