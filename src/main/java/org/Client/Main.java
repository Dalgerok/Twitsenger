package main.java.org.Client;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import javafx.stage.Stage;

import java.io.IOException;
import java.sql.*;

public class Main extends Application{
    private final String url = "jdbc:postgresql://94.245.108.117:5432/facebook";
    private final String user = "nazarii";
    private final String password = "1234";

    static Stage primaryStage;

    static StartSceneController startSceneController;
    static RegisterSceneController registerSceneController;
    static MainSceneController mainSceneController;

    static Scene startScene;
    static Scene registerScene;
    static Scene mainScene;

    public static void setRegisterScene() {
        primaryStage.setScene(registerScene);
    }

    @Override
    public void start(Stage primaryStage) {
        Main.primaryStage = primaryStage;
        createContent();

        primaryStage.setHeight(800);
        primaryStage.setWidth(800);
        primaryStage.setResizable(false);
        primaryStage.setOnCloseRequest(windowEvent -> System.exit(0));
        primaryStage.setScene(mainScene);
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
        Connection sqlConnection = main.connect();


        String SQL = "SELECT * FROM \"User\" ORDER BY first_name";
        try {
            Statement statement = sqlConnection.createStatement();
            ResultSet rs = statement.executeQuery(SQL);
            displayUser(rs);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }


        launch(args);

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