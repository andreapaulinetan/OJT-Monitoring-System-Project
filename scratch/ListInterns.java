import java.sql.*;
public class ListInterns {
    public static void main(String[] args) {
        try {
            Connection c = DriverManager.getConnection("jdbc:derby:./database/active_learning_db");
            ResultSet rs = c.createStatement().executeQuery("SELECT INTERN_ID, FIRST_NAME, LAST_NAME FROM APP.INTERN");
            while (rs.next()) {
                System.out.println(rs.getString(1) + " | " + rs.getString(2) + " " + rs.getString(3));
            }
            c.close();
        } catch (Exception e) { e.printStackTrace(); }
    }
}
