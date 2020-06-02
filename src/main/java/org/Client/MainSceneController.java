package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.geometry.Pos;
import javafx.scene.control.Button;
import javafx.scene.control.ListView;
import javafx.scene.control.Separator;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;



public class MainSceneController {
    @FXML public AnchorPane mainAnchorPane;

    public void logoutButtonHandler(MouseEvent mouseEvent) {
        Main.logout();
    }

    public void editMyProfileHandler(MouseEvent mouseEvent) {
        Main.setEditProfileScene();
    }

    public void myFriendsHandler(MouseEvent mouseEvent) {
        Main.setMyProfileScene();
    }

    public void postsHandler(MouseEvent mouseEvent) {
        Main.setPostsScene();
    }
}
