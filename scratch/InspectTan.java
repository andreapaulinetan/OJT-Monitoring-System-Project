package scratch;

import java.sql.*;
import util.CryptoUtil;

public class InspectTan {
    public static void main(String[] args) {
        String url = "jdbc:derby://localhost:1527/ojt_AuthenticationDB";
        String user = "app";
        String pwd = "app";
        
        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            System.out.println("Connecting to Apache Derby...");
            try (Connection conn = DriverManager.getConnection(url, user, pwd)) {
                System.out.println("CONNECTED.");
                
                String query = "SELECT * FROM APP.INTERN WHERE LOWER(EMAIL) = 'andreapauline.tan.be@gmail.com'";
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery(query)) {
                    if (rs.next()) {
                        ResultSetMetaData md = rs.getMetaData();
                        int cols = md.getColumnCount();
                        System.out.println("\n--- INTERN RECORD FOUND ---");
                        for (int i = 1; i <= cols; i++) {
                            System.out.println(md.getColumnName(i) + ": " + rs.getString(i));
                        }
                        
                        String storedPwd = rs.getString("PASSWORD");
                        if (storedPwd != null) {
                            System.out.println("\nPassword starts with enc: " + storedPwd.startsWith("enc:"));
                            if (storedPwd.startsWith("enc:")) {
                                try {
                                    String decrypted = CryptoUtil.decrypt(storedPwd.substring(4));
                                    System.out.println("Decrypted password: " + decrypted);
                                } catch (Exception e) {
                                    System.out.println("Failed to decrypt password: " + e.getMessage());
                                }
                            }
                        }
                    } else {
                        System.out.println("\nNo record found for email andreapauline.tan.be@gmail.com");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
