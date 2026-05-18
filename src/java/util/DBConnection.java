package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.servlet.ServletContext;

public class DBConnection {

    // Method for DBMS 1 (Apache Derby) 
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

// Method for DBMS 2 (MySQL) 
public static Connection getMySQLMonitoringConnection(ServletContext context) {
    try {
        Class.forName(context.getInitParameter("mysql.driver"));
        
        String baseUrl = context.getInitParameter("mysql.url");
        
        return DriverManager.getConnection(
                baseUrl,
                context.getInitParameter("mysql.username"),
                context.getInitParameter("mysql.password")
        );
    } catch (Exception e) {
        e.printStackTrace();
        return null;
    }
}
    // Method for DBMS 3 (PostgreSQL) 
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