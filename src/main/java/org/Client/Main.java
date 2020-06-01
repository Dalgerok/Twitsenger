package main.java.org.Client;

import javafx.application.Application;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.layout.Pane;
import javafx.stage.Stage;
import main.java.org.Tools.ConnectionMessage;
import main.java.org.Tools.LoginInfo;
import main.java.org.Tools.RegisterInfo;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.net.Socket;

public class Main extends Application{

    static Stage primaryStage;

    static StartSceneController startSceneController;
    static RegisterSceneController registerSceneController;
    static MainSceneController mainSceneController;

    static Scene startScene;
    static Scene registerScene;
    static Scene mainScene;

    public static void setRegisterScene() {
        primaryStage.setScene(registerScene);
        registerSceneController.messageText.setVisible(false);
    }

    public static void setStartScene() {
        primaryStage.setScene(startScene);
        registerSceneController.messageText.setVisible(false);
    }

    public static void setMainScene() {
        primaryStage.setScene(mainScene);
    }

    private static final String hostname = "localhost";
    private static final int port = 4001;
    private static Socket clientSocket;
    private static ObjectInputStream in;
    private static ObjectOutputStream out;
    public static void signUp(RegisterInfo registerInfo) {
        if (!connect())return;
        if (!sendObject(registerInfo))return;
        Object o = getObject();
        if (ConnectionMessage.SIGN_UP.equals(o)){
            startRead();
            setMainScene();
        }else {
            disconnect();
        }
    }

    public static void signIn(LoginInfo loginInfo) {
        if (!connect())return;
        sendObject(loginInfo);
        Object o = getObject();
        if (ConnectionMessage.SIGN_IN.equals(o)){
            startRead();
            setMainScene();
        }else{
            disconnect();
        }
    }

    public static void logout() {
        disconnect();
        setStartScene();
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

    private static <T extends Serializable> boolean sendObject(T o) {
        if (clientSocket == null || out == null)return false;
        try{
            synchronized (out){
                out.writeObject(o);
            }
            return true;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }
    public static Object getObject() {
        if (clientSocket == null || in == null)return null;
        try{
            Object o;
            synchronized (in) {
                o = in.readObject();
                return o;
            }
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

        ObservableList<MainSceneController.PostPane> posts = FXCollections.observableArrayList();
        posts.addAll(new MainSceneController.PostPane(), new MainSceneController.PostPane(), new MainSceneController.PostPane());
        mainSceneController.postView.setItems(posts);
    }
    private void createContent(){
        initStartScene();
        initRegisterScene();
        initMainScene();
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
    private void initMainScene(){
        FXMLLoader mainLoader = new FXMLLoader(getClass().getResource("/main/resources/fxml/mainScene.fxml"));
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



    public static void main(String[] args) {
        Main main = new Main();
        launch(args);
    }

    public static class ObjectReader extends Thread {
        @Override
        public void run() {
            System.out.println("STARTED READING");
            while (!isInterrupted()) {
                try {
                    System.out.println("start receiving");
                    //Object obj = getObjectForReader();
                    Object obj;
                    synchronized (in){
                        obj = getObject();
                    }
                    System.out.println("RECEIVED " + obj);

                } catch (Exception e) {
                    System.out.println("SERVER DOWN");
                    //Platform.runLater(() -> returnToStart("SERVER DOWN"));
                    // TODO: 02.06.2020
                }
            }
            //System.out.println("STOPPED READING");
        }
    }
}