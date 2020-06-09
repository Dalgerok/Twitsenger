package org.twitterissimo.server;

import org.twitterissimo.tools.*;

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
            synchronized (out) {
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
                    String s;
                    if (!info.getUpdate())
                        s = sqlUpdQuery("INSERT INTO users (first_name, last_name, birthday, email, relationship_status, gender, user_password) VALUES ( " +
                            compose(info.getFirstName(), info.getLastName(), info.getBirthday(), info.getEmail(),
                                    info.getRelationship(), info.getGender(), info.getPassword()) + "" +
                            " );");
                    else {
                        System.out.println("SOMETHING WRONG IN REGISTER");
                        return;
                    }
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
                ArrayList<ServerUser> arr1 = getUserFriends(user.user_id);arr1.add(0, new ServerUser());arr1.get(0).first_name = "myFriends";
                sendObject(arr1);
                while (true) {
                    obj = readObject();
                    System.out.println("received " + obj);
                    if (ConnectionMessage.GET_ALL_POSTS.equals(obj)) {
                        System.out.println("I WANNA TO SEND POSTS!!!");
                        ArrayList<Post> arr = getAllPosts();
                        arr.add(0, new Post());
                        sendObject(arr);
                    } else if(ConnectionMessage.GET_FRIENDS_POSTS.equals(obj)){
                        System.out.println("I WANNA TO SEND FRIENDS POST!!!" + user.user_id);
                        ArrayList<Post> arr = getFriendsPosts(user.user_id);
                        arr.add(0, new Post());
                        sendObject(arr);
                    } else if (obj instanceof ConnectionMessage) {
                        if (ConnectionMessage.NEW_POST.equals(obj)) {
                            obj = readObject();
                            if (obj instanceof Post) {
                                System.out.println("NEW POST " + obj);
                                Post p = (Post) obj;
                                System.out.println("TEXT LENGTH IS: " + p.post_text.length());
                                if(p.reposted_from == 0) {
                                    sqlUpdQuery("INSERT INTO posts VALUES(" + compose(String.valueOf(user.user_id), p.post_text) + ");");
                                }
                                else{
                                    sqlUpdQuery("INSERT INTO posts(user_id, post_text, reposted_from) VALUES(" + compose(String.valueOf(user.user_id),
                                            p.post_text, String.valueOf(p.reposted_from)) + ");"    );
                                }
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
                        } else if (ConnectionMessage.NEW_LIKE.equals(obj)){
                            obj = readObject();
                            if(obj instanceof Post){
                                System.out.println("NEW LIKE " + obj);
                                Post p = (Post) obj;
                                sqlUpdQuery("INSERT INTO like_sign VALUES(" + compose(String.valueOf(p.post_id), String.valueOf(user.user_id)) + ");");
                                sendAll(ConnectionMessage.UPDATE_POSTS);
                            } else {
                                System.out.println("BAD NEW LIKE!!!");
                            }
                        } else if (ConnectionMessage.ID_BY_LOCATION.equals(obj)){
                            obj = readObject();
                            if (obj instanceof String) {
                                System.out.println("ID BY LOC");
                                int kol = getIdByLocation((String)obj);
                                sendObject(kol);
                            } else {
                                System.out.println("BAD ID BY LOC");
                            }
                        }
                    } else if (obj instanceof ProfileRequest) {
                        ProfileRequest pr = (ProfileRequest) obj;
                        sendObject(getProfileInfo(pr.getId()));
                    } else if (obj instanceof RegisterInfo) {

                        System.out.println("TRYING TO UPDATE PROFILE");
                        RegisterInfo info = (RegisterInfo)obj;
                        String s;
                        if (info.getUpdate()) {
                            System.out.println("kek");
                            String location = "null";
                            if (!info.getLocation_id().equals("-1")) {
                                location = compose(info.getLocation_id());
                            }
                            s = sqlUpdQuery("UPDATE users SET first_name = " + compose(info.getFirstName()) +
                                    ", last_name = " + compose(info.getLastName()) + ", user_password = " + compose(info.getPassword()) + ", birthday = " + compose(info.getBirthday()) +
                                    ", relationship_status = " + compose(info.getRelationship()) + ", gender = " + compose(info.getGender()) + ", picture_url = " + compose(info.getPictureURL()) + ", user_location_id = " + location +
                                    " WHERE email = " + compose(email) + ";");
                            System.out.println(s);
                        }
                        else {
                            System.out.println("SOMETHING WRONG IN UPDATE");
                            continue;
                        }
                        if ("ok".equals(s)) {
                            sendObject(ConnectionMessage.UPDATED_PROFILE);
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
                            //return;
                        } else {
                            sendObject(ConnectionMessage.BAD_EMAIL);
                            //return;
                        }
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
                    } else if (obj instanceof GetUserFriendRequests) {
                        GetUserFriendRequests getUFR = (GetUserFriendRequests)obj;
                        ArrayList<UserRequest> arr = getUserFriendRequests(getUFR.id);
                        arr.add(0, new UserRequest());
                        sendObject(arr);
                    } else if (obj instanceof FriendStatusChange){
                        FriendStatusChange fsc = (FriendStatusChange)obj;
                        if (fsc.query == FriendStatusChange.FriendQuery.ADD){
                            sqlUpdQuery("INSERT INTO friend_request VALUES (" + fsc.from.user_id + ", " + fsc.to.user_id + ");");
                        }else if (fsc.query == FriendStatusChange.FriendQuery.REMOVE){
                            sqlUpdQuery("DELETE FROM friendship f WHERE f.friend1 = " + fsc.from.user_id + "AND f.friend2 = " + fsc.to.user_id + ";");
                        } else if (fsc.query == FriendStatusChange.FriendQuery.REMOVE_REQUEST) {
                            sqlUpdQuery("DELETE FROM friend_request WHERE from_whom = " + fsc.from.user_id + " AND to_whom = " + fsc.to.user_id + ";");
                        }

                        ArrayList<ServerUser> arr;
                        for (ConnectionThread conn : connections){
                            //System.out.println("hah, spijmav");
                            if (conn.user.user_id == fsc.from.user_id){
                                arr = getUserFriends(fsc.from.user_id);arr.add(0, new ServerUser());arr.get(0).first_name = "myFriends";
                                conn.sendObject(arr);
                            }
                        }
                        for (ConnectionThread conn : connections){
                            //System.out.println("hah, spijmav");
                            if (conn.user.user_id == fsc.to.user_id){
                                arr = getUserFriends(fsc.to.user_id);arr.add(0, new ServerUser());arr.get(0).first_name = "myFriends";
                                conn.sendObject(arr);
                            }
                        }
                    } else if (obj instanceof FacilitySearcher) {
                        FacilitySearcher facilitySearcher = (FacilitySearcher)obj;
                        ArrayList<Facility> arr = getSearchFacilities(facilitySearcher);
                        arr.add(0, new Facility());
                        sendObject(arr);
                    } else if (obj instanceof UserFacility) {
                        UserFacility userFacility = (UserFacility)obj;
                        if (userFacility.add)
                            addUserFacility(userFacility);
                        else
                            delUserFacility(userFacility);
                    } else if (obj instanceof Facility) {
                        int id = addFacility((Facility)obj);
                        sendObject(id);
                    } else if (obj instanceof Location) {
                        int id = addLocation((Location)obj);
                        sendObject(id);
                    }else if (obj instanceof Message){
                        Message message = (Message)obj;
                        sqlUpdQuery("INSERT INTO messages VALUES(" + compose(message.from.user_id+"", message.to.user_id+"", message.text) + ");");
                        UserMessages um = getMessages(message.from.user_id, message.to.user_id);
                        um.reason = "just update";
                        ArrayList<ChatItem> arr2 = getChats(message.from.user_id);
                        arr2.add(0, new ChatItem());
                        for (ConnectionThread conn : connections){
                            if (conn.user.user_id == message.from.user_id){
                                conn.sendObject(um);
                                conn.sendObject(arr2);
                            }
                        }
                        um = getMessages(message.to.user_id, message.from.user_id);
                        um.reason = "just update";
                        arr2 = getChats(message.to.user_id);
                        arr2.add(0, new ChatItem());
                        for (ConnectionThread conn : connections){
                            if (conn.user.user_id == message.to.user_id){
                                conn.sendObject(um);
                                conn.sendObject(arr2);
                            }
                        }
                    }else if (obj instanceof UserMessages){
                        UserMessages um = (UserMessages)obj;
                        UserMessages answer = getMessages(um.myId, um.otherId);
                        answer.reason = "you asked";
                        sendObject(answer);
                    }else if (obj instanceof ChatItem){
                        ChatItem chatItem = (ChatItem)obj;
                        ArrayList<ChatItem> arr = getChats(chatItem.me.user_id);
                        arr.add(0, new ChatItem());
                        sendObject(arr);
                    }
                }
            } catch (IOException e) {
                System.out.println("client disconnected");
                e.printStackTrace();
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


        private ArrayList<Post> getPosts(Integer user_id) {
            ResultSet rs;
            ArrayList<Post> posts = new ArrayList<>();
            String SQL = "SELECT *, get_number_of_likes_on_post(pp.post_id) as post_likes, " +
                    "get_number_of_likes_on_post(p.post_id) as repost_likes " +
                    "FROM posts pp JOIN users kek ON pp.user_id = kek.user_id " +
                    "LEFT JOIN posts p ON pp.reposted_from = p.post_id " +
                    "LEFT JOIN users us ON p.user_id = us.user_id ";
            if (user_id != null) SQL = SQL + "WHERE pp.user_id = " + user_id + " ";
            SQL = SQL + "ORDER BY pp.post_date DESC, pp.post_id DESC;";



            rs = sqlGetQuery(SQL);
            if (rs != null) {
                try {
                    ResultSetMetaData rsmd = rs.getMetaData();
                    System.out.println("HAHA BRO " + rsmd.getColumnName(16));
                    while (rs.next()) {
                        user_id = rs.getInt("user_id");
                        String post_text = rs.getString("post_text");
                        Timestamp post_time = rs.getTimestamp("post_date");
                        int reposted_from = rs.getInt("reposted_from");
                        int post_id = rs.getInt("post_id");
                        String first_name = rs.getString("first_name");
                        String last_name = rs.getString("last_name");
                        String user_picture_url = rs.getString("picture_url");
                        int post_number_of_likes = rs.getInt("post_likes");
                        // TODO: 02.06.2020 ADD NUMBER OF LIKES AND REPOSTS
                        if(reposted_from == 0) {
                            posts.add(new Post(
                                    user_id, post_text, post_time,
                                    reposted_from, post_id, first_name,
                                    last_name, user_picture_url, post_number_of_likes));
                            System.out.println("ADD POST " + posts.get(posts.size() - 1).post_id);
                        }
                        else{
                            int rep_user_id = rs.getInt(16);
                            String rep_post_text = rs.getString(17);
                            Timestamp rep_post_time = rs.getTimestamp(18);
                            int rep_reposted_from = rs.getInt(19);
                            int rep_post_id = rs.getInt(20);
                            String rep_first_name = rs.getString(21);
                            String rep_last_name = rs.getString(22);
                            String rep_user_picture_url = rs.getString(29);
                            int repost_number_of_likes = rs.getInt(32);
                            Post repost = new Post(
                                    rep_user_id, rep_post_text, rep_post_time,
                                    rep_reposted_from, rep_post_id, rep_first_name,
                                    rep_last_name, rep_user_picture_url, repost_number_of_likes);
                            System.out.println("WTF " + repost.post_id);
                            posts.add(new Post(
                                    user_id, post_text, post_time,
                                    reposted_from, post_id, first_name,
                                    last_name, user_picture_url, repost, post_number_of_likes));
                            System.out.println("ADD POST_REPOST " + posts.get(posts.size() - 1).post_id + " " + posts.get(posts.size() - 1));
                        }
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            return posts;
        }
        private ArrayList<Post> getAllPosts() {
            ResultSet rs;
            ArrayList<Post> posts = new ArrayList<>();
            String SQL = "SELECT * FROM get_refactored_all_posts;";

            rs = sqlGetQuery(SQL);
            if (rs != null) {
                try {
                    ResultSetMetaData rsmd = rs.getMetaData();
                    System.out.println("HAHA BRO " + rsmd.getColumnName(16));
                    while (rs.next()) {
                        int user_id = rs.getInt("user_id");
                        String post_text = rs.getString("post_text");
                        Timestamp post_time = rs.getTimestamp("post_date");
                        int reposted_from = rs.getInt("reposted_from");
                        int post_id = rs.getInt("post_id");
                        String first_name = rs.getString("first_name");
                        String last_name = rs.getString("last_name");
                        String user_picture_url = rs.getString("picture_url");
                        int post_number_of_likes = rs.getInt("post_likes");
                        // TODO: 02.06.2020 ADD NUMBER OF LIKES AND REPOSTS
                        if(reposted_from == 0) {
                            posts.add(new Post(
                                    user_id, post_text, post_time,
                                    reposted_from, post_id, first_name,
                                    last_name, user_picture_url, post_number_of_likes));
                            System.out.println("ADD POST " + posts.get(posts.size() - 1).post_id);
                        }
                        else{
                            int rep_user_id = rs.getInt(16);
                            String rep_post_text = rs.getString(17);
                            Timestamp rep_post_time = rs.getTimestamp(18);
                            int rep_reposted_from = rs.getInt(19);
                            int rep_post_id = rs.getInt(20);
                            String rep_first_name = rs.getString(21);
                            String rep_last_name = rs.getString(22);
                            String rep_user_picture_url = rs.getString(29);
                            int repost_number_of_likes = rs.getInt("repost_likes");
                            Post repost = new Post(
                                    rep_user_id, rep_post_text, rep_post_time,
                                    rep_reposted_from, rep_post_id, rep_first_name,
                                    rep_last_name, rep_user_picture_url, repost_number_of_likes);
                            System.out.println("WTF " + repost.post_id);
                            posts.add(new Post(
                                    user_id, post_text, post_time,
                                    reposted_from, post_id, first_name,
                                    last_name, user_picture_url, repost, post_number_of_likes));
                            System.out.println("ADD POST_REPOST " + posts.get(posts.size() - 1).post_id + " " + posts.get(posts.size() - 1));
                        }
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            return posts;
        }
        private ArrayList<Post> getFriendsPosts(Integer user_id) {
            ResultSet rs;
            ArrayList<Post> posts = new ArrayList<>();
            String SQL = "SELECT *, get_number_of_likes_on_post(pp.post_id) as post_likes, " +
                    "get_number_of_likes_on_post(p.post_id) as repost_likes" +
                    "  FROM posts pp " +
                    "JOIN get_user_friends_with_user(" + user_id + ") kek ON pp.user_id = kek.user_id " +
                    "LEFT JOIN posts p ON pp.reposted_from = p.post_id LEFT JOIN users us ON p.user_id = us.user_id ";
            SQL = SQL + "ORDER BY pp.post_date DESC, pp.post_id DESC;";

            rs = sqlGetQuery(SQL);
            if (rs != null) {
                try {
                    ResultSetMetaData rsmd = rs.getMetaData();
                    System.out.println("HAHA BRO " + rsmd.getColumnName(16));
                    while (rs.next()) {
                        user_id = rs.getInt("user_id");
                        String post_text = rs.getString("post_text");
                        Timestamp post_time = rs.getTimestamp("post_date");
                        int reposted_from = rs.getInt("reposted_from");
                        int post_id = rs.getInt("post_id");
                        String first_name = rs.getString("first_name");
                        String last_name = rs.getString("last_name");
                        String user_picture_url = rs.getString("picture_url");
                        int post_number_of_likes = rs.getInt("post_likes");
                        // TODO: 02.06.2020 ADD NUMBER OF LIKES AND REPOSTS
                        if(reposted_from == 0) {
                            posts.add(new Post(
                                    user_id, post_text, post_time,
                                    reposted_from, post_id, first_name,
                                    last_name, user_picture_url, post_number_of_likes));
                            System.out.println("ADD POST " + posts.get(posts.size() - 1).post_id);
                        }
                        else{
                            Integer rep_user_id = rs.getInt(16);
                            String rep_post_text = rs.getString(17);
                            Timestamp rep_post_time = rs.getTimestamp(18);
                            int rep_reposted_from = rs.getInt(19);
                            int rep_post_id = rs.getInt(20);
                            String rep_first_name = rs.getString(21);
                            String rep_last_name = rs.getString(22);
                            String rep_user_picture_url = rs.getString(29);
                            int repost_number_of_likes = rs.getInt(32);
                            Post repost = new Post(
                                    rep_user_id, rep_post_text, rep_post_time,
                                    rep_reposted_from, rep_post_id, rep_first_name,
                                    rep_last_name, rep_user_picture_url, repost_number_of_likes);
                            System.out.println("WTF " + repost.post_id);
                            posts.add(new Post(
                                    user_id, post_text, post_time,
                                    reposted_from, post_id, first_name,
                                    last_name, user_picture_url, repost, post_number_of_likes));
                            System.out.println("ADD POST_REPOST " + posts.get(posts.size() - 1).post_id + " " + posts.get(posts.size() - 1));
                        }
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            return posts;
        }

        private UserMessages getMessages(int id1, int id2) {
            UserMessages um = new UserMessages();
            um.me = getUserInfo(id1);
            um.other = getUserInfo(id2);
            um.myId = id1;
            um.otherId = id2;
            String SQL = "SELECT * FROM messages WHERE (user_from = " + id1 + " AND user_to = " + id2 + ") OR (user_from = " + id2 + " AND user_to = " + id1 + ")" +
                    " ORDER BY message_date, message_id;";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null){
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            ArrayList<Message> messages = new ArrayList<>();
            try{
                while (rs.next()){
                    if (rs.getInt("user_from") == id1) {
                        messages.add(new Message(um.me, um.other, rs.getString("message_text"), rs.getTimestamp("message_date")));
                    }else {
                        messages.add(new Message(um.other, um.me, rs.getString("message_text"), rs.getTimestamp("message_date")));
                    }
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            um.messages = messages;
            return um;
        }

        private ArrayList<ChatItem> getChats(int id){
            ServerUser me = getUserInfo(id);
            String SQL = "SELECT get_latest_message(" + id + ", user_id)  from users WHERE get_latest_message(" + id + ", user_id) IS NOT NULL;";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null){
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            ArrayList<Integer> arr = new ArrayList<>();
            try{
                while (rs.next()){
                    arr.add(rs.getInt(1));
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            ArrayList<ChatItem> answer = new ArrayList<>();
            for (int i : arr){
                Message message = getMessage(i);
                if (message.from.user_id == id)answer.add(new ChatItem(message.from, message.to, message));else
                    answer.add(new ChatItem(message.to, message.from, message));
            }
            answer.sort((o1, o2) -> -o1.message.timestamp.compareTo(o2.message.timestamp));
            return answer;
        }

        private Message getMessage(int id){
            ResultSet rs = sqlGetQuery("SELECT * FROM messages WHERE message_id = " + id + ";");
            if (rs == null) {
                System.out.println("PROBLEMS WITH SQL");
                System.exit(0);
            }
            try {
                rs.next();
                //System.out.println(rs.getInt("user_location_id"));
                int id1 = rs.getInt(1);
                int id2 = rs.getInt(2);
                String text = rs.getString(3);
                Timestamp date = rs.getTimestamp(4);
                return new Message(getUserInfo(id1), getUserInfo(id2), text, date);
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return null;
        }

        private ProfileInfo getUserInfo(int user_id) {
            ResultSet rs = sqlGetQuery("SELECT * FROM users WHERE users.user_id = " + user_id + ";");
            if (rs == null) {
                System.out.println("PROBLEMS WITH SQL");
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

            String SQL = "SELECT * FROM user_facilities WHERE user_id = " + user_id + ";";
            ResultSet rs = sqlGetQuery(SQL);
            ArrayList<UserFacility> userFacilities = new ArrayList<>();
            if (rs == null) {
                System.out.println("VERY VERY BAD (IMPOSSIBLE)");
                System.exit(0);
            }
            try {
                while (rs.next()) {
                    userFacilities.add(new UserFacility(rs.getInt(1), rs.getInt(2), rs.getTimestamp(3), rs.getTimestamp(4), rs.getString(5)));
                    System.out.println("KEK " + rs.getInt(1) + " " + rs.getInt(2));
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
            for (UserFacility userFacility : userFacilities){
                userFacility.setFacility(getFacility(userFacility.facilityId));
            }
            pi.facilities = userFacilities;
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
            String SQL = "SELECT * FROM get_user_friends(" + user_id + ");";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null){
                System.out.println("PROBLEMS WITH SQL");
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
        private ArrayList<UserRequest> getUserFriendRequests(int user_id) {
            String SQL = "SELECT from_whom  FROM friend_request WHERE to_whom = " + user_id + ";";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null) {
                return new ArrayList<>();
            }
            ArrayList<UserRequest> userRequests = new ArrayList<>();
            try {
                ArrayList<Integer> arrUserId = new ArrayList<>();
                while(rs.next()) {
                    arrUserId.add(rs.getInt(1));
                }
                for (int i = 0; i < arrUserId.size(); i++) {
                    ProfileInfo profileInfo = getProfileInfo(arrUserId.get(i));
                    userRequests.add(new UserRequest(profileInfo));
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return userRequests;
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
            String SQL = "SELECT * FROM facilities WHERE facilities.facility_id = " + facility_id + ";";
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

        private ArrayList<Facility> getSearchFacilities(FacilitySearcher searcher){
            String SQL = "SELECT facility_name, facility_location, facility_id FROM facilities WHERE check_facility_filter(facilities, " + compose(searcher.facility_name, searcher.facility_type) + ") = TRUE;";
            ResultSet rs = sqlGetQuery(SQL);
            if (rs == null){
                System.out.println("VERY VERY BAD (IMOPOSSIBLE)");
                System.exit(0);
            }
            ArrayList<Facility> facilities = new ArrayList<>();
            try {
                ArrayList<String> facNames = new ArrayList<>();
                ArrayList<Integer> locIds = new ArrayList<>();
                ArrayList<Integer> facIds = new ArrayList<>();
                while(rs.next()){
                    facNames.add(rs.getString(1));
                    locIds.add(rs.getInt(2));
                    facIds.add(rs.getInt(3));
                }
                for (int i = 0; i < facNames.size(); i++){
                    String name = facNames.get(i);
                    int location_id = locIds.get(i);
                    int facility_id = facIds.get(i);
                    facilities.add(new Facility(name, getLocation(location_id), searcher.facility_type, facility_id));
                }
            } catch (SQLException e){
                e.printStackTrace();
            }
            return facilities;
        }

        private ArrayList<ServerUser> getUsersByFilter(SearchProfileFilter filter){
            String SQL = "SELECT * FROM users WHERE check_user_filter(users, " +
compose(filter.firstName, filter.lastName, filter.country, filter.city, filter.facilityId + "") + ", ";
            if (filter.dateFrom != null)SQL = SQL + "'" + filter.dateFrom.toString() + "',";else SQL = SQL + "NULL,";
            if (filter.dateTo != null)SQL = SQL + "'" + filter.dateTo.toString() + "'";else SQL = SQL + "NULL";
            SQL = SQL +
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

        private int addFacility(Facility facility) {
            String SQL = "INSERT INTO facilities(facility_name, facility_location, facility_type)" +
                    " VALUES (" + compose(facility.name, Integer.toString(facility.location.location_id), facility.type) + ");";
            sqlUpdQuery(SQL);
            SQL = "SELECT facility_id from facilities WHERE facility_name = " + compose(facility.name) + " AND facility_location = " +
                    compose(Integer.toString(facility.location.location_id)) + " AND facility_type = " + compose(facility.type) + ";";
            ResultSet rs = sqlGetQuery(SQL);
            try {
                if (rs == null || !rs.next()) {
                    return -2;
                }
                else
                    return rs.getInt(1)*2+1;
            } catch(SQLException e) {
                e.printStackTrace();;
                return -2;
            }
        }


        private int addLocation(Location location) {
            String SQL = "INSERT INTO locations(country, city)" +
                    " VALUES (" + compose(location.country,  location.city) + ");";
            sqlUpdQuery(SQL);
            SQL = "SELECT location_id from locations WHERE country = " + compose(location.country) + "AND city = " + compose(location.city) + ";";
            ResultSet rs = sqlGetQuery(SQL);
            try {
                if (rs == null || !rs.next()) {
                    return -2;
                }
                else
                    return rs.getInt(1)*2;
            } catch(SQLException e) {
                e.printStackTrace();;
                return -2;
            }
        }

        private void addUserFacility(UserFacility facility){
            String SQL;
            if (facility.date_to == null){
                SQL = "INSERT INTO user_facilities (user_id, facility_id, date_from, description) " +
                        "VALUES (" + compose(Integer.toString(facility.userId), Integer.toString(facility.facilityId), facility.date_from.toString(), facility.description) + ");";
            }
            else {
                SQL = "INSERT INTO user_facilities (user_id, facility_id, date_from, date_to, description) " +
                        "VALUES (" + compose(Integer.toString(facility.userId), Integer.toString(facility.facilityId), facility.date_from.toString(), facility.date_to.toString(), facility.description) + ");";
            }
            sqlUpdQuery(SQL);
        }

        private void delUserFacility(UserFacility facility) {
            sqlUpdQuery("DELETE FROM user_facilities WHERE user_id=" + compose(Integer.toString(facility.userId)) +
                    " AND facility_id=" + compose(Integer.toString(facility.facilityId)) + " AND date_from=" + compose(facility.date_from.toString()) + ";");
        }

        private int getIdByLocation(String location) {
            String[] arr = location.split(":");
            String country = arr[0], city = arr[1];
            String SQL = "SELECT location_id FROM locations WHERE country = " + compose(country) + " AND city = " + compose(city) + ";";
            ResultSet rs = sqlGetQuery(SQL);
            try {
                if (rs == null || !rs.next())
                    return -2;
                else return rs.getInt(1)*2;
            } catch (SQLException e) {
                e.printStackTrace();
                return -2;
            }
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
