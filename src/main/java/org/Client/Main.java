package main.java.org.Client;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.control.ListView;
import javafx.scene.input.KeyCode;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import main.java.org.Tools.ConnectionMessage;
import main.java.org.Tools.LoginInfo;
import main.java.org.Tools.Post;
import main.java.org.Tools.RegisterInfo;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.net.ConnectException;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collection;

public class Main extends Application{

    static Stage primaryStage;

    static StartSceneController startSceneController;
    static RegisterSceneController registerSceneController;
    static MainSceneController mainSceneController;
    static PostsSceneController postsSceneController;

    static Scene startScene;
    static Scene registerScene;
    static Scene mainScene;
    static Scene postsScene;

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
        // TODO: 02.06.2020  
    }
    public static void setMyProfileScene() {
        setMainScene();
        // TODO: 02.06.2020
    }
    public static void setPostsScene() {
        setMainScene();
        updatePostsScene();
        System.out.println("SET POSTS SCENE");
        mainSceneController.mainAnchorPane.getChildren().add(postsSceneController.postsVBox);
    }

    private static final String hostname = "localhost";
    private static final int port = 4001;
    private static Socket clientSocket;
    private static ObjectInputStream in;
    private static ObjectOutputStream out;
    public static ConnectionMessage signUp(RegisterInfo registerInfo) {
        if (!connect())return ConnectionMessage.UNABLE_TO_CONNECT;
        if (!sendObject(registerInfo))return ConnectionMessage.UNABLE_TO_CONNECT;
        Object o = getObject();
        if (ConnectionMessage.SIGN_UP.equals(o)){
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
            //e.printStackTrace();
            System.out.println("Can't load startScene");
            System.exit(0);
        }
        mainSceneController = mainLoader.getController();
        mainScene = new Scene(mainPane);
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
    public static void updatePostsScene(){
        System.out.println("UPDATE POSTS SCENE");
        ObservableList<PostsSceneController.PostPane> l = FXCollections.observableArrayList();
        sendObject(ConnectionMessage.GET_POSTS);
        Object o = getObject();
        System.out.println("GOT " + o);
        ArrayList<Post> list = (ArrayList<Post>)o;
        for(Post p : list){
            l.add(new PostsSceneController.PostPane(p));
        }
        postsSceneController.postView.setItems(l);
    }

    private static void sendMessage(String s) {
        System.out.println("SEND MESSAGE " + s);
        sendObject(new Post(s));
        updatePostsScene();
    }


    public static void main(String[] args) {
        Main main = new Main();
        launch(args);
    }
}