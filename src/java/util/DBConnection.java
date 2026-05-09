package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.servlet.ServletContext;

/**
 * Member 1: Centralized Database Connection Utility
 * Fetches credentials from web.xml to prevent hardcoding.
 */
public class DBConnection {

    // Method for DBMS 1 (Apache Derby) - Member 1 & 4's focus
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

    // Method for DBMS 2 (MySQL) - Member 2's focus
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

    // Method for DBMS 3 (PostgreSQL) - Member 3's focus
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