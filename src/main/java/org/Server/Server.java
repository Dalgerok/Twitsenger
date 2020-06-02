package main.java.org.Server;

import main.java.org.Tools.ConnectionMessage;
import main.java.org.Tools.LoginInfo;
import main.java.org.Tools.RegisterInfo;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.sql.*;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;


public class Server {
    private static final String url = "jdbc:postgresql://localhost:5432/postgres";
    private static final String user = "postgres";
    private static final String password = "1321";
    private static Connection sqlConnection;
    private static Statement sqlStatement;

    private static ResultSet sqlGetQuery(String SQL){
        try {
            if (sqlConnection == null || sqlConnection.isClosed())sqlConnection = connectToSQL();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
            return null;
        }
        try {
            return sqlStatement.executeQuery(SQL);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
        return null;
    }
    private static String sqlUpdQuery(String SQL){
        try {
            if (sqlConnection == null || sqlConnection.isClosed())sqlConnection = connectToSQL();
        } catch (SQLException e) {
            e.printStackTrace();
            return "bad connection";
        }
        try {
            System.out.println(sqlStatement.execute(SQL));
            return "ok";
        } catch (SQLException e) {
            System.out.println(e.getLocalizedMessage());
            String[] s = e.toString().split("\"");
            if(s.length == 3){
                return s[1];
            }
            else{
                return s[3];
            }
        }
    }
    public static Connection connectToSQL() {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(url, user, password);
            sqlStatement = conn.createStatement();
            System.out.println("Connected to the PostgreSQL server successfully.");
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return null;
        }

        return conn;
    }



    public static void main(String[] args) {
        final int portNumber = 4001;
        try {
            ServerSocket serverSocket = new ServerSocket(portNumber);
            while (true){
                Socket socket = serverSocket.accept();
                System.out.println("accepted");
                new ConnectionThread(socket).start();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    private static final CopyOnWriteArrayList<ConnectionThread> connections = new CopyOnWriteArrayList<>();
    public static class ConnectionThread extends Thread {
        private final Socket socket;
        private final ObjectInputStream in;
        private final ObjectOutputStream out;

        public ConnectionThread(Socket socket) throws IOException {
            this.socket = socket;
            this.in = new ObjectInputStream(this.socket.getInputStream());
            this.out = new ObjectOutputStream(this.socket.getOutputStream());
            connections.add(this);
        }

        String email = null;
        @Override
        public void run() {
            Object obj;
            try {
                obj  = readObject();
                System.out.println(obj);
                if (obj instanceof RegisterInfo){
                    RegisterInfo info = (RegisterInfo)obj;
                    email = info.getEmail();
                    String s = sqlUpdQuery("INSERT INTO users (first_name, last_name, birthday, email, relationship_status, gender, user_password) VALUES ( " +
                            compose(info.getFirstName(), info.getLastName(), info.getBirthday(), info.getEmail(),
                                    info.getRelationship(), info.getGender(), info.getPassword()) + "" +
                            " );");
                    if ("ok".equals(s)){
                        sendObject(ConnectionMessage.SIGN_UP);
                    }else if("ch_user_birthday".equals(s)){
                        sendObject(ConnectionMessage.BAD_BIRTHDAY);
                        return;
                    }else{
                        sendObject(ConnectionMessage.BAD_EMAIL);
                        return;
                    }
                }else if (obj instanceof LoginInfo){
                    LoginInfo info = (LoginInfo)obj;
                    email = info.getEmail();
                    ResultSet rs = sqlGetQuery("SELECT check_email(" + info.getEmail() + ");");
                    try {
                        if (rs == null || !rs.next()){
                            sendObject(ConnectionMessage.BAD_EMAIL);
                            return;
                        }else {
                            if (!rs.getBoolean(1)){
                                sendObject(ConnectionMessage.BAD_EMAIL);
                                return;
                            }
                        }
                    } catch (SQLException throwables) {
                        throwables.printStackTrace();
                        return;
                    }
                    rs = sqlGetQuery("SELECT check_password(" + compose(info.getEmail(), info.getPassword()) + ");");
                    try {
                        if (rs == null || !rs.next()){
                            sendObject(ConnectionMessage.BAD_PASSWORD);
                            return;
                        }else {
                            if (!rs.getBoolean(1)){
                                sendObject(ConnectionMessage.BAD_PASSWORD);
                                return;
                            }
                        }
                    } catch (SQLException throwables) {
                        throwables.printStackTrace();
                        return;
                    }
                    sendObject(ConnectionMessage.SIGN_IN);
                }else return;
                System.out.println("logined or registered");
                while (true) {
                    obj = readObject();
                    System.out.println("received " + obj);
                }
            } catch(IOException e){
                System.out.println("client disconnected");
            } finally{

                try {
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                System.out.println(email + " is disconnected");
            }
        }
        public void sendObject(Object o) throws IOException {
            System.out.println("Something sent " + o);
            synchronized (out){
                out.writeObject(o);
            }
        }
        public Object readObject() throws IOException {
            try {
                synchronized (in){
                    return in.readObject();
                }
            } catch (IOException e) {
                throw e;
            } catch (ClassNotFoundException e) {
                System.out.println("bad class impossible");
                e.printStackTrace();
                return null;
            }
        }
    }
    static String compose(String... args){
        StringBuilder s = new StringBuilder();
        for (int i = 0; i < args.length; ++i){
            if (i > 0) s.append(", ");
            s.append(args[i]);
        }
        return s.toString();
    }
}
