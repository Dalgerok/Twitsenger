package main.java.org.Server;

import javafx.geometry.Pos;
import main.java.org.Tools.*;
import org.postgresql.core.SqlCommand;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.sql.*;
import java.util.ArrayList;
import java.util.concurrent.CopyOnWriteArrayList;


public class Server {
    private static final String url = "jdbc:postgresql://localhost:5432/postgres";
    private static final String user = "postgres";
    private static final String password = "1321";



    public static void main(String[] args) {
        //String SQL = "SELECT * FROM users";
        //sqlConnection = connectToSQL();
        /*Connection connection1 = connectToSQL();
        Connection connection2 = connectToSQL();
        try {
            Statement statement1 = connection1.createStatement();
            Statement statement2 = connection2.createStatement();
            statement1.executeQuery(SQL);
            statement2.executeQuery(SQL);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }*/

        //getUserInfo(1);
        final int portNumber = 4321;
        try {
            ServerSocket serverSocket = new ServerSocket(portNumber);
            while (true){
                System.out.println("I'm here!");
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
        private ServerUser user;
        private Connection sqlConnection;
        private  Statement sqlStatement;

        public ConnectionThread(Socket socket) throws IOException {
            this.socket = socket;
            this.in = new ObjectInputStream(this.socket.getInputStream());
            this.out = new ObjectOutputStream(this.socket.getOutputStream());
            connections.add(this);
        }
        private ResultSet sqlGetQuery(String SQL){

            System.out.println("GET QUERY: " + SQL);
            try {
                if (sqlConnection == null || sqlConnection.isClosed())sqlConnection = connectToSQL();
            } catch (SQLException throwables) {
                return null;
            }
            try {
                return sqlStatement.executeQuery(SQL);
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            return null;
        }
        private String sqlUpdQuery(String SQL){
            System.out.println("QUERY: " + SQL);
            try {
                if (sqlConnection == null || sqlConnection.isClosed())sqlConnection = connectToSQL();
            } catch (SQLException e) {
                e.printStackTrace();
                return "bad connection";
            }
            try {
                sqlStatement.execute(SQL);
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
        public Connection connectToSQL() {
            Connection conn;
            try {
                conn = DriverManager.getConnection(Server.url, Server.user, Server.password);
                sqlStatement = conn.createStatement();
                System.out.println("Connected to the PostgreSQL server successfully.");
            } catch (SQLException e) {
                System.out.println(e.getMessage());
                return null;
            }

            return conn;
        }

        String email = null;

        @Override
        public void run() {
            Object obj;
            try {
                obj = readObject();
                System.out.println(obj);
                if (obj instanceof RegisterInfo) {
                    RegisterInfo info = (RegisterInfo) obj;
                    email = info.getEmail();
                    String s = sqlUpdQuery("INSERT INTO users (first_name, last_name, birthday, email, relationship_status, gender, user_password) VALUES ( " +
                            compose(info.getFirstName(), info.getLastName(), info.getBirthday(), info.getEmail(),
                                    info.getRelationship(), info.getGender(), info.getPassword()) + "" +
                            " );");
                    if ("ok".equals(s)) {
                        sendObject(ConnectionMessage.SIGN_UP);
                        ResultSet rs = sqlGetQuery("SELECT * FROM users WHERE users.email = " + compose(info.getEmail()) + ";");
                        if (rs == null) {
                            System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                            System.exit(0);
                        }
                        try {
                            rs.next();
                            user = new ServerUser(rs.getString("first_name"), rs.getString("last_name"), rs.getDate("birthday"),
                                    rs.getString("email"), rs.getString("relationship_status"), rs.getString("gender"),
                                    rs.getString("user_password"), rs.getInt("user_location_id"), rs.getString("picture_url"),
                                    rs.getInt("user_id"));
                            sendObject(user);
                        } catch (SQLException e) {
                            e.printStackTrace();
                        }
                    } else if ("ch_user_birthday".equals(s)) {
                        sendObject(ConnectionMessage.BAD_BIRTHDAY);
                        return;
                    } else {
                        sendObject(ConnectionMessage.BAD_EMAIL);
                        return;
                    }
                } else if (obj instanceof LoginInfo) {
                    LoginInfo info = (LoginInfo) obj;
                    email = info.getEmail();
                    ResultSet rs = sqlGetQuery("SELECT check_email(" + compose(info.getEmail()) + ");");
                    try {
                        if (rs == null || !rs.next()) {
                            sendObject(ConnectionMessage.BAD_EMAIL);
                            return;
                        } else {
                            if (!rs.getBoolean(1)) {
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
                        if (rs == null || !rs.next()) {
                            sendObject(ConnectionMessage.BAD_PASSWORD);
                            return;
                        } else {
                            if (!rs.getBoolean(1)) {
                                sendObject(ConnectionMessage.BAD_PASSWORD);
                                return;
                            }
                        }
                    } catch (SQLException throwables) {
                        throwables.printStackTrace();
                        return;
                    }
                    sendObject(ConnectionMessage.SIGN_IN);
                    rs = sqlGetQuery("SELECT * FROM users WHERE users.email = " + compose(info.getEmail()) + ";");
                    if (rs == null) {
                        System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                        System.exit(0);
                    }
                    try {
                        rs.next();
                        user = new ServerUser(rs.getString("first_name"), rs.getString("last_name"), rs.getDate("birthday"),
                                rs.getString("email"), rs.getString("relationship_status"), rs.getString("gender"),
                                rs.getString("user_password"), rs.getInt("user_location_id"), rs.getString("picture_url"),
                                rs.getInt("user_id"));
                        sendObject(user);
                    } catch (SQLException e) {
                        e.printStackTrace();
                    }
                } else return;
                System.out.println("logined or registered");
                while (true) {
                    obj = readObject();
                    System.out.println("received " + obj);
                    if (ConnectionMessage.GET_POSTS.equals(obj)) {
                        System.out.println("I WANNA TO SEND POSTS!!!");
                        ArrayList<Post> arr = getPosts(null);
                        arr.add(0, new Post());
                        sendObject(arr);
                    } else if (obj instanceof ConnectionMessage) {
                        if (ConnectionMessage.NEW_POST.equals(obj)) {
                            obj = readObject();
                            if (obj instanceof Post) {
                                System.out.println("NEW POST " + obj);
                                Post p = (Post) obj;
                                sqlUpdQuery("INSERT INTO posts VALUES(" + compose(String.valueOf(user.user_id), p.post_text) + ");");
                            } else {
                                System.out.println("BAD NEW POST!!!");
                            }
                            sendAll(ConnectionMessage.UPDATE_POSTS);
                        } else if (ConnectionMessage.DEL_POST.equals(obj)) {
                            obj = readObject();
                            if (obj instanceof Post) {
                                System.out.println("DEL POST " + obj);
                                Post p = (Post) obj;
                                sqlUpdQuery("DELETE FROM posts WHERE posts.post_id=" + p.post_id + ";");
                            } else {
                                System.out.println("BAD DEL POST!!!");
                            }
                            sendAll(ConnectionMessage.UPDATE_POSTS);
                        }
                    } else if (obj instanceof ProfileRequest) {
                        ProfileRequest pr = (ProfileRequest) obj;
                        sendObject(getProfileInfo(pr.getId()));
                    }else if (obj instanceof SearchProfileFilter){
                        SearchProfileFilter spf = (SearchProfileFilter)obj;
                        ArrayList<ServerUser> arr = getUsersByFilter(spf);
                        arr.add(0, new ServerUser());
                        arr.get(0).first_name = "search";
                        sendObject(arr);
                    }else if (obj instanceof GetUserFriends){
                        GetUserFriends guf = (GetUserFriends)obj;
                        ArrayList<ServerUser> arr = getUserFriends(guf.id);
                        arr.add(0, new ServerUser());
                        arr.get(0).first_name = "friends";
                        sendObject(arr);
                    }
                }
            } catch (IOException e) {
                System.out.println("client disconnected");
            } finally {

                try {
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                System.out.println(email + " is disconnected");
                connections.remove(this);
            }
        }

        private void sendAll(Object o) {
            for (ConnectionThread connectionThread : connections) {
                try {
                    connectionThread.sendObject(o);
                } catch (IOException e) {
                    //e.printStackTrace();
                }
            }
        }

        public void sendObject(Object o) throws IOException {
            System.out.println("Something sent " + o);
            out.writeObject(o);
        }

        public Object readObject() throws IOException {
            try {
                return in.readObject();
            } catch (IOException e) {
                throw e;
            } catch (ClassNotFoundException e) {
                System.out.println("bad class impossible");
                e.printStackTrace();
                return null;
            }
        }

        private ArrayList<Post> getPosts(Integer user_id) {
            ResultSet rs;
            ArrayList<Post> posts = new ArrayList<>();
            String SQL = "SELECT * FROM posts JOIN users ON posts.user_id = users.user_id ";
            if (user_id != null) SQL = SQL + "WHERE posts.user_id = " + user_id + " ";
            SQL = SQL + "ORDER BY post_date DESC;";

            rs = sqlGetQuery(SQL);
            if (rs != null) {
                try {
                    while (rs.next()) {
                        user_id = rs.getInt(1);
                        String post_text = rs.getString(2);
                        Timestamp post_time = rs.getTimestamp(3);
                        int reposted_from = rs.getInt(4);
                        int post_id = rs.getInt(5);
                        String first_name = rs.getString(6);
                        String last_name = rs.getString(7);
                        String user_picture_url = rs.getString("picture_url");
                        // TODO: 02.06.2020 ADD NUMBER OF LIKES AND REPOSTS
                        posts.add(new Post(
                                user_id, post_text, post_time,
                                reposted_from, post_id, first_name,
                                last_name, user_picture_url));
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            return posts;
        }

        private ProfileInfo getUserInfo(int user_id) {
            ResultSet rs = sqlGetQuery("SELECT * FROM users WHERE users.user_id = " + user_id + ";");
            if (rs == null) {
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            try {
                rs.next();
                //System.out.println(rs.getInt("user_location_id"));
                return new ProfileInfo(rs.getString("first_name"), rs.getString("last_name"), rs.getDate("birthday"),
                        rs.getString("email"), rs.getString("relationship_status"), rs.getString("gender"),
                        rs.getString("user_password"), rs.getInt("user_location_id"), rs.getString("picture_url"),
                        rs.getInt("user_id"));
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return null;
        }

        private ProfileInfo getProfileInfo(int user_id) {
            ProfileInfo pi = getUserInfo(user_id);
            if (pi.user_location_id != 0) {
                pi.location = getLocation(pi.user_location_id);
            }
            pi.posts = getPosts(user_id);
            pi.numFriends = getNumberOfUserFriends(user_id);
            pi.numPosts = getNumberOfUserPosts(user_id);

            String SQL = "SELECT facility_id FROM user_facilities WHERE user_id = " + user_id + ";";
            ResultSet rs = sqlGetQuery(SQL);
            ArrayList<Facility> facilities = new ArrayList<>();
            ArrayList<Integer> facility_ids = new ArrayList<>();
            if (rs == null) {
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            try {
                while (rs.next()) {
                    facility_ids.add(rs.getInt(1));
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            for (int id : facility_ids){
                facilities.add(getFacility(id));
            }
            pi.facilities = facilities;
            return pi;
        }
        private int getNumberOfUserFriends(int user_id){
            String SQL = "SELECT get_number_of_user_friends(" + user_id + ");";
            ResultSet rs = sqlGetQuery(SQL);
            try{
                if (rs == null || !rs.next()) {

                }else {
                    return rs.getInt(1);
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            return 0;
        }
        private ArrayList<ServerUser> getUserFriends(int user_id){
            String SQL = "SELECT * FROM get_user_friend(" + user_id + ");";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null){
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            ArrayList<ServerUser> users = new ArrayList<>();
            try{
                while (rs.next()){
                    users.add(new ServerUser(rs.getString("first_name"), rs.getString("last_name"), rs.getDate("birthday"),
                            rs.getString("email"), rs.getString("relationship_status"), rs.getString("gender"),
                            rs.getString("user_password"), rs.getInt("user_location_id"), rs.getString("picture_url"),
                            rs.getInt("user_id")));
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            return users;
        }
        private int getNumberOfUserPosts(int user_id){
            String SQL = "SELECT get_number_of_user_posts(" + user_id + ");";
            ResultSet rs = sqlGetQuery(SQL);
            try{
                if (rs == null || !rs.next()) {

                }else {
                    return rs.getInt(1);
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            return 0;
        }

        private Location getLocation(int location_id) {
            String SQL = "SELECT * FROM locations WHERE locations.location_id = " + location_id + ";";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null) {
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            try {
                if (!rs.next()) {
                    return new Location("", "", location_id);
                } else {
                    return new Location(rs.getString(1), rs.getString(2), location_id);
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            return new Location("", "", location_id);
        }

        private Facility getFacility(int facility_id) {
            String SQL = "SELECT * FROM facilities WHERE facility.facility_id = " + facility_id + ";";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null) {
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            try {
                if (!rs.next()) {
                    return new Facility("", new Location("", "", 0), "", facility_id);
                } else {
                    String name = rs.getString(1);
                    int location_id = rs.getInt(2);
                    String type = rs.getString(3);
                    return new Facility(name, getLocation(location_id), type, facility_id);
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            return new Facility("", new Location("", "", 0), "", facility_id);
        }
        private ArrayList<ServerUser> getUsersByFilter(SearchProfileFilter filter){
            String SQL = "SELECT * FROM users WHERE check_user_filter(users, " + compose(   filter.firstName, filter.lastName, filter.country, filter.city) +
                    ")  = TRUE;";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null){
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            ArrayList<ServerUser> users = new ArrayList<>();
            try{
                while (rs.next()){
                    users.add(new ServerUser(rs.getString("first_name"), rs.getString("last_name"), rs.getDate("birthday"),
                            rs.getString("email"), rs.getString("relationship_status"), rs.getString("gender"),
                            rs.getString("user_password"), rs.getInt("user_location_id"), rs.getString("picture_url"),
                            rs.getInt("user_id")));
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            return users;
        }
    }
    static String compose(String... args){
        StringBuilder s = new StringBuilder();
        for (int i = 0; i < args.length; ++i){
            if (i > 0) s.append(", ");
            s.append("'").append(args[i]).append("'");
        }
        return s.toString();
    }
}
