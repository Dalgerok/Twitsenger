package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.geometry.Pos;
import javafx.scene.control.Button;
import javafx.scene.control.ListView;
import javafx.scene.control.Separator;
import javafx.scene.control.TextField;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;

import java.sql.Timestamp;


public class PostsSceneController {
    @FXML public ListView<PostPane> postView;
    @FXML public VBox postsVBox;
    @FXML public TextField enterMessage;

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

        public PostPane(int user_id, String post_text, Timestamp post_time, int reposted_from, int post_id, String first_name, String last_name, String user_picture_url) {
            super();

            HBox user = new HBox();
            ImageView userIcon = new ImageView(); // TODO: 02.06.2020 add picture_url
            Text userName = new Text(first_name + " " + last_name);
            user.getChildren().addAll(userIcon, userName);


            Text postText = new Text(post_text);


            HBox buttons = new HBox();
            Button like = new Button("like");
            Button repost = new Button("repost");
            buttons.getChildren().addAll(like, repost);

            Separator separator = new Separator();

            getChildren().addAll(user, postText, buttons, separator);
        }
    }
}
