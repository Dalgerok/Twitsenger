package org.twitterissimo.client;

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
        Main.setEditProfileScene(Main.user.user_id);
    }

    //public void myFriendsHandler(MouseEvent mouseEvent) {
    //    Main.setMyProfileScene();
    //}

    public void postsHandler(MouseEvent mouseEvent) {
        Main.setPostsScene();
    }

    public void myFriendsHandler(MouseEvent mouseEvent) {
        Main.setFriendsScene(Main.user.user_id);
        // TODO: 03.06.2020
    }

    public void myProfileHandler(MouseEvent mouseEvent) {
        System.out.println(Main.user + "hfjfdkfj");
        Main.setProfileScene(Main.user.user_id);
    }

    public void findFriendsHandler(MouseEvent mouseEvent) {
        Main.setSearchScene();
        // TODO: 04.06.2020
    }

    public void chatsHandler(MouseEvent event) {
        Main.setChatsScene();
    }
}
