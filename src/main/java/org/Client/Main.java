package main.java.org.Client;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.input.KeyCode;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import main.java.org.Tools.*;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.net.Socket;
import java.util.ArrayList;

public class Main extends Application{

    static Stage primaryStage;

    static StartSceneController startSceneController;
    static RegisterSceneController registerSceneController;
    static MainSceneController mainSceneController;
    static PostsSceneController postsSceneController;
    static ProfileSceneController profileSceneController;

    static Scene startScene;
    static Scene registerScene;
    static Scene mainScene;
    static ClientPlace clientPlace;

    public static void setRegisterScene() {
        System.out.println("SET REGISTER SCENE");
        primaryStage.setScene(registerScene);
        registerSceneController.messageText.setVisible(false);
    }

    public static void setStartScene() {
        System.out.println("SET START SCENE");
        primaryStage.setScene(startScene);
        startSceneController.textMessage.setVisible(false);
        registerSceneController.messageText.setVisible(false);
    }

    public static void setMainScene() {
        System.out.println("SET MAIN SCENE");
        initMainScene();
        primaryStage.setScene(mainScene);
    }
    public static void setEditProfileScene() {
        setMainScene();

        clientPlace = ClientPlace.EDIT_PROFILE_SCENE;
        // TODO: 02.06.2020  
    }
    public static void setProfileScene(int id) {
        setMainScene();
        askForProfileInfo(id);
        System.out.println("SET PROFILE SCENE " + id);
        mainSceneController.mainPane.getChildren().add(profileSceneController.profilePane);

        clientPlace = ClientPlace.PROFILE_SCENE;
        // TODO: 02.06.2020
    }
    public static void setPostsScene() {
        setMainScene();
        askForUpdatePostsScene();
        System.out.println("SET POSTS SCENE");
        mainSceneController.mainPane.getChildren().add(postsSceneController.postsVBox);

        clientPlace = ClientPlace.POST_SCENE;
    }

    private static final String hostname = "localhost";
    private static final int port = 4321;
    private static Socket clientSocket;
    private static ObjectInputStream in;
    private static ObjectOutputStream out;
    public static ServerUser user;
    public static ConnectionMessage signUp(RegisterInfo registerInfo) {
        if (!connect())return ConnectionMessage.UNABLE_TO_CONNECT;
        if (!sendObject(registerInfo))return ConnectionMessage.UNABLE_TO_CONNECT;
        Object o = getObject();
        if (ConnectionMessage.SIGN_UP.equals(o)){
            o = getObject();
            if(!(o instanceof ServerUser)){
                disconnect();
                return ConnectionMessage.UNABLE_TO_CONNECT;
            }
            user = (ServerUser)o;
            startRead();
            setPostsScene();
            return ConnectionMessage.SIGN_UP;
        }else {
            disconnect();
            return (ConnectionMessage)o;
        }
    }

    public static ConnectionMessage signIn(LoginInfo loginInfo) {
        if (!connect())return ConnectionMessage.UNABLE_TO_CONNECT;
        sendObject(loginInfo);
        Object o = getObject();
        if (ConnectionMessage.SIGN_IN.equals(o)){
            o = getObject();
            if(!(o instanceof ServerUser)){
                disconnect();
                return ConnectionMessage.UNABLE_TO_CONNECT;
            }
            user = (ServerUser)o;
            startRead();
            setPostsScene();
            return ConnectionMessage.SIGN_IN;
        }
        else {
            disconnect();
            return (ConnectionMessage)o;
        }
    }

    public static void logout() {
        disconnect();
        setStartScene();
    }

    private static <T extends Serializable> boolean sendObject(T o) {
        System.out.println("Send object " + o);
        if (clientSocket == null || out == null)return false;
        try{
            out.writeObject(o);
            return true;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }
    public static Object getObject() {
        System.out.println("STREAM ONE " + (in == null));
        if (clientSocket == null || in == null)return null;
        System.out.println("STREAM TWO " + (in == null));
        try{
            Object o;
            System.out.println("IM HERE");
            o = in.readObject();
            System.out.println("READ " + o);
            return o;
        } catch (IOException | ClassNotFoundException e) {
            e.printStackTrace();
            disconnect();
            //System.exit(0);
        }
        return null;
    }

    private static boolean connect() {
        try{
            clientSocket = new Socket(hostname, port);
            System.out.println(clientSocket.isConnected());
            out = new ObjectOutputStream(clientSocket.getOutputStream());
            in = new ObjectInputStream(clientSocket.getInputStream());
            System.out.println("Established connection");
            return true;
        } catch (IOException e) {
            //e.printStackTrace();
            System.out.println("cannot connect");
            disconnect();
            return false;
        }
    }
    public static void disconnect() {
        stopRead();
        try{
            in = null;
            out = null;
            if (clientSocket != null)clientSocket.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
        System.out.println("DISCONNECTED SUCCESSFULLY");
    }


    @Override
    public void start(Stage primaryStage) {
        Main.primaryStage = primaryStage;
        createContent();

        primaryStage.setHeight(800);
        primaryStage.setWidth(800);
        primaryStage.setResizable(false);
        primaryStage.setOnCloseRequest(windowEvent -> System.exit(0));
        primaryStage.setScene(startScene);
        primaryStage.show();
    }
    private void createContent(){
        initStartScene();
        initRegisterScene();
        initMainScene();
        initPostsScene();
        initProfileScene();
    }
    private void initStartScene() {
        FXMLLoader startLoader = new FXMLLoader(getClass().getResource("/main/resources/fxml/startScene.fxml"));
        Pane startPane = null;
        try {
            startPane = startLoader.load();
        } catch (Exception e) {
            //e.printStackTrace();
            System.out.println("Can't load startScene");
            System.exit(0);
        }
        startSceneController = startLoader.getController();

        startSceneController.loginButton.setOnKeyPressed(ke -> {
            if (ke.getCode().equals(KeyCode.ENTER)) {
                startSceneController.loginButtonHandler(null);
            }
        });
        startPane.setOnKeyPressed(ke -> {
            if (ke.getCode().equals(KeyCode.ENTER)) {
                startSceneController.loginButtonHandler(null);
            }
        });
        startScene = new Scene(startPane);
    }
    private void initRegisterScene() {
        FXMLLoader registerLoader = new FXMLLoader(getClass().getResource("/main/resources/fxml/registerScene.fxml"));
        Pane registerPane = null;
        try {
            registerPane = registerLoader.load();
        } catch (IOException e) {
            //e.printStackTrace();
            System.out.println("Can't load registerScene");
            System.exit(0);
        }
        registerSceneController = registerLoader.getController();
        registerScene = new Scene(registerPane);
    }
    private static void initMainScene(){
        FXMLLoader mainLoader = new FXMLLoader(Main.class.getResource("/main/resources/fxml/mainScene.fxml"));
        Pane mainPane = null;
        try {
            mainPane = mainLoader.load();
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Can't load mainScene");
            System.exit(0);
        }
        mainSceneController = mainLoader.getController();
        mainScene = new Scene(mainPane);
    }
    private static void initProfileScene(){
        FXMLLoader mainLoader = new FXMLLoader(Main.class.getResource("/main/resources/fxml/profileScene.fxml"));
        Pane profilePane = null;
        try {
            profilePane = mainLoader.load();
        } catch (Exception e) {
            //e.printStackTrace();
            System.out.println("Can't load profileScene");
            System.exit(0);
        }
        profileSceneController = mainLoader.getController();
    }
    private static void initPostsScene(){
        FXMLLoader postsLoader = new FXMLLoader(Main.class.getResource("/main/resources/fxml/postsScene.fxml"));
        VBox kek = null;
        try{
            kek = postsLoader.load();
        } catch (Exception e){
            System.out.println("Can't load postsScene");
            System.exit(0);
        }
        postsSceneController = postsLoader.getController();
        postsSceneController.enterMessage.setOnKeyTyped(event -> {
            String string = postsSceneController.enterMessage.getText();

            if (string.length() > 250) {
                postsSceneController.enterMessage.setText(string.substring(0, 250));
                postsSceneController.enterMessage.positionCaret(string.length());
            }
        });
        postsSceneController.enterMessage.setOnKeyPressed(ke -> {
            if (ke.getCode().equals(KeyCode.ENTER))
            {
                String s = postsSceneController.enterMessage.getText();
                if(!s.isEmpty()){
                    sendMessage(s);
                }
                postsSceneController.enterMessage.clear();
            }
        });
    }
    public static void askForUpdatePostsScene(){
        System.out.println("ASK FOR UPDATE POSTS SCENE");
        sendObject(ConnectionMessage.GET_POSTS);
    }
    public static void updatePostsScene(ArrayList<Post> list){
        System.out.println("UPDATE POSTS SCENE");
        ObservableList<PostsSceneController.PostPane> l = FXCollections.observableArrayList();
        for(Post p : list){
            l.add(new PostsSceneController.PostPane(p, user.user_id));
        }
        postsSceneController.postView.setItems(l);
    }
    private static void updateProfileScene(ProfileInfo pi) {
        System.out.println("UPDATE PROFILE SCENE");
        profileSceneController.updateProfile(pi);
    }
    public static void askForProfileInfo(int id){
        System.out.println("ASK FOR USER INFO");
        sendObject(new ProfileRequest(id));
    }

    private static void sendMessage(String s) {
        System.out.println("SEND MESSAGE " + s);
        sendObject(ConnectionMessage.NEW_POST);
        sendObject(new Post(s));
        askForUpdatePostsScene();
    }
    public static void delMessage(Post p) {
        System.out.println("DEL MESSAGE " + p);
        sendObject(ConnectionMessage.DEL_POST);
        sendObject(p);

        sendObject(new ProfileRequest(user.user_id));
        askForUpdatePostsScene();
    }


    public static void main(String[] args) {
        Main main = new Main();
        launch(args);
    }
    private static ObjectReader reader = null;

    private static void startRead() {
        reader = new ObjectReader();
        reader.start();
    }
    private static void stopRead(){
        System.out.println("Stop read");
        if (reader != null && !reader.isInterrupted()){
            System.out.println("Interrupting...  DSFDVRWWFDWWRDWGR");
            reader.interrupt();
        }
    }
    public static class ObjectReader extends Thread {
        @Override
        public void run() {
            System.out.println("STARTED READING");
            while (!isInterrupted()) {
                try {
                    System.out.println("start receiving");
                    Object obj;
                    synchronized (in){
                        obj = getObject();
                    }
                    System.out.println("RECEIVED " + obj);
                    if (obj instanceof ConnectionMessage){
                        if (obj.equals(ConnectionMessage.UPDATE_POSTS)){
                            if (clientPlace.equals(ClientPlace.PROFILE_SCENE))askForProfileInfo(profileSceneController.profileId);
                            if (clientPlace.equals(ClientPlace.POST_SCENE))askForUpdatePostsScene();
                        }
                    }
                    if (obj instanceof ArrayList){
                        if (((ArrayList) obj).size() > 0 && ((ArrayList) obj).get(0) instanceof Post)Platform.runLater(() -> updatePostsScene((ArrayList<Post>) obj));
                    }
                    if (obj instanceof ProfileInfo)Platform.runLater(() -> updateProfileScene((ProfileInfo)obj));
                } catch (Exception e) {
                    System.out.println("SERVER DOWN");
                    e.printStackTrace();
                    // TODO: 02.06.2020
                }
            }
            //System.out.println("STOPPED READING");
        }

    }
}