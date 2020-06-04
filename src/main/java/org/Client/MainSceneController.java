package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.Pane;

import java.security.ProtectionDomain;


public class MainSceneController {
    @FXML public AnchorPane mainAnchorPane;
    @FXML public Pane mainPane;
    public Button findFriendsButton;

    public void logoutButtonHandler(MouseEvent mouseEvent) {
        Main.logout();
    }

    public void editMyProfileHandler(MouseEvent mouseEvent) {
        Main.setEditProfileScene();
    }

    //public void myFriendsHandler(MouseEvent mouseEvent) {
    //    Main.setMyProfileScene();
    //}

    public void postsHandler(MouseEvent mouseEvent) {
        Main.setPostsScene();
    }

    public void myFriendsHandler(MouseEvent mouseEvent) {
        // TODO: 03.06.2020
    }

    public void myProfileHandler(MouseEvent mouseEvent) {
        System.out.println(Main.user + "hfjfdkfj");
        Main.setProfileScene(Main.user.user_id);
    }

    public void findFriendsHandler(MouseEvent mouseEvent) {
        // TODO: 04.06.2020
    }
}
