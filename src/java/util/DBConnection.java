package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.servlet.ServletContext;

/**
 * Centralized Database Connection Utility
 * Fetches credentials from web.xml to prevent hardcoding.
 */
public class DBConnection {

    // 1. Primary Derby Connection (AuthDB - Member 1 & 4)
    public static Connection getDerbyConnection(ServletContext context) {
        try {
            Class.forName(context.getInitParameter("derby.driver"));
            return DriverManager.getConnection(
                context.getInitParameter("derby.url"),
                context.getInitParameter("derby.username"),
                context.getInitParameter("derby.password")
            );
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            return null;
        }
    }

    // 2. OJT Derby Connection (OJTDB - Used for Dashboard stats)
    public static Connection getOJTDerbyConnection(ServletContext context) {
        try {
            Class.forName(context.getInitParameter("derby.driver"));
            return DriverManager.getConnection(
                    context.getInitParameter("ojt.derby.url"), 
                    context.getInitParameter("derby.username"),
                    context.getInitParameter("derby.password")
            );
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            return null;
        }
    }

    // 3. MySQL Connection (Member 2)
    public static Connection getMySQLConnection(ServletContext context) {
        try {
            Class.forName(context.getInitParameter("mysql.driver"));
            return DriverManager.getConnection(
                context.getInitParameter("mysql.url"),
                context.getInitParameter("mysql.username"),
                context.getInitParameter("mysql.password")
            );
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            return null;
        }
    }

    // 4. PostgreSQL Connection (Member 3)
    public static Connection getPgConnection(ServletContext context) {
        try {
            Class.forName(context.getInitParameter("pgsql.driver"));
            return DriverManager.getConnection(
                context.getInitParameter("pgsql.url"),
                context.getInitParameter("pgsql.username"),
                context.getInitParameter("pgsql.password")
            );
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
}