package main.java.org.Server;

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
    private static final String url = "jdbc:postgresql://localhost:5433/twitmess";
    private static final String user = "postgres";
    private static final String password = "1321";
    private static Connection sqlConnection;
    private static Statement sqlStatement;

    private static ResultSet sqlGetQuery(String SQL){
        try {
            if (sqlConnection.isClosed())sqlConnection = connectToSQL();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
        try {
            return sqlStatement.executeQuery(SQL);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
        return null;
    }
    private static boolean sqlUpdQuery(String SQL){
        try {
            if (sqlConnection.isClosed())sqlConnection = connectToSQL();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
        try {
            return sqlStatement.execute(SQL);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
        return false;
    }
    public static Connection connectToSQL() {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(url, user, password);
            sqlStatement = conn.createStatement();
            System.out.println("Connected to the PostgreSQL server successfully.");
        } catch (SQLException e) {
            System.out.println(e.getMessage());
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

        @Override
        public void run() {
            Object obj;
            try {
                obj  = readObject();
                System.out.println(obj);
                if (obj instanceof RegisterInfo){
                    RegisterInfo info = (RegisterInfo)obj;
                    sqlUpdQuery("INSERT INTO users (first_name, last_name, birthday, email, relationship_status, gender, user_password) VALUES ( " +
                                compose(info.getFirstName(), info.getLastName(), info.getBirthday(), info.getEmail(),
                                        info.getRelationship(), info.getGender(), info.getPassword()) + "" +
                                " );");
                }else if (obj instanceof )
                //System.out.println("i am here");
                while (true) {
                    obj = readObject();
                    System.out.println("received " + obj);
                    if (obj.equals(ConnectionMessage.RETURN_TO_MENU)){
                        sendObject(ConnectionMessage.STOP_READING);
                        player.reset();
                        continue;
                    }
                    if (!player.inLobby()){
                        if (obj instanceof String){
                            System.out.println("i am here");
                            String[] msg = ((String)obj).split(":");
                            int maxPlayers = Integer.parseInt(msg[0]);
                            boolean isPrivate = (Integer.parseInt(msg[1])%2 == 1);
                            Server.createNewLobby(player, isPrivate, maxPlayers, msg[2], msg[3]);
                            continue;
                        }
                        if (!(obj instanceof ConnectionMessage)){
                            System.out.println("not get com.charades.tools.ConnectionMessage");
                            break;
                        }
                        ConnectionMessage msg = (ConnectionMessage)obj;
                        if (msg.equals(ConnectionMessage.CONNECT_TO_LOBBY)){
                            obj = readObject();
                            if (!(obj instanceof String)){
                                System.out.println("not get String");
                                break;
                            }
                            String ID = (String)obj;
                            System.out.println(ID);
                            if (!lobbyIDs.containsKey(ID)){
                                sendObject(ConnectionMessage.BAD_ID);
                                continue;
                            }
                            if (lobbyIDs.get(ID).isFull()){
                                sendObject(ConnectionMessage.LOBBY_FULL);
                                continue;
                            }
                            lobbyIDs.get(ID).addPlayer(player);
                        }
                        if (msg.equals(ConnectionMessage.LOBBY_LIST)){
                            ArrayList<String> arr = new ArrayList<>();
                            for (Lobby lobby : lobbyIDs.values()){
                                if (!lobby.isPrivate()){
                                    arr.add(lobby.getMetadata());
                                }
                            }
                            sendObject(arr.size());
                            for (String metadata : arr){
                                sendObject(metadata);
                            }
                        }
                    }else {
                        player.getLobby().handleMessage(obj, player);
                    }
                }
            } catch(IOException e){
                System.out.println("client disconnected");
            } finally{
                if (player != null){
                    //System.out.println("CLOSING LOBBY " + player.getLobby().empty());
                    if (player.inLobby()){
                        player.getLobby().removePlayer(player);
                        if (player.getLobby().empty()){
                            player.getLobby().closeLobby();
                        }
                    }
                    usernames.remove(player.getUsername());
                }
                try {
                    socket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                System.out.println(player + " is disconnected");
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
