package main.java.org.Client;

import java.sql.*;

public class Main{
    private final String url = "jdbc:postgresql://94.245.108.117:5432/facebook";
    private final String user = "nazarii";
    private final String password = "1234";
    public static void main(String[] args) {
        Main main = new Main();
        Connection sqlConnection = main.connect();


        String SQL = "SELECT * FROM \"User\"";
        String haha = "\"aha\"";
        try {
            Statement statement = sqlConnection.createStatement();
            ResultSet rs = statement.executeQuery(SQL);
            displayUser(rs);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }
    private static void displayUser(ResultSet rs) throws SQLException {
        while (rs.next()){
            System.out.println(rs.getString("first_name") + "\t" + rs.getString("last_name") + "\t" +
                    rs.getString("birthday"));

        }
    }
    public Connection connect() {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(url, user, password);
            System.out.println("Connected to the PostgreSQL server successfully.");
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }

        return conn;
    }
}