package main.java.org.Client;

import javafx.geometry.Pos;
import javafx.scene.control.Button;
import javafx.scene.control.ListView;
import javafx.scene.control.Separator;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;



public class MainSceneController {


    public ListView<PostPane> postView;

    public void logoutButtonHandler(MouseEvent mouseEvent) {
        Main.logout();
    }

    public static class PostPane extends VBox{
        public PostPane(){
            super();


            HBox user = new HBox();
            ImageView userIcon = new ImageView();
            Text userName = new Text("Name Surname");
            user.getChildren().addAll(userIcon, userName);


            Text postText = new Text("It's my post text");


            HBox buttons = new HBox();
            Button like = new Button("like");
            Button repost = new Button("repost");
            buttons.getChildren().addAll(like, repost);

            Separator separator = new Separator();

            getChildren().addAll(user, postText, buttons, separator);
        }
    }
}
