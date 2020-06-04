package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;
import main.java.org.Tools.Post;

import java.io.Serializable;
import java.sql.Timestamp;


public class PostsSceneController {
    @FXML public ListView<PostPane> postView;
    @FXML public VBox postsVBox;
    @FXML public TextArea enterMessage;

    public void refreshButtonHandler(MouseEvent mouseEvent) {
        Main.askForUpdatePostsScene();
    }

    public static class PostPane extends VBox implements Serializable {
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

        public PostPane(int user_id, String post_text, Timestamp post_time, int reposted_from, int post_id, String first_name, String last_name, String user_picture_url)  {
            super();
            System.out.println("NEW POST_PANE " + first_name + " " + last_name);
            HBox user = new HBox();
            ImageView userIcon = new ImageView(); // TODO: 02.06.2020 add picture_url
            Text userName = new Text(first_name + " " + last_name);
            user.getChildren().addAll(userIcon, userName);
            user.setVisible(true);


            Text postText = new Text(post_text);


            HBox buttons = new HBox();
            //Button like = new Button("like");
            //Button repost = new Button("repost");
            //buttons.getChildren().addAll(like, repost);

            //Separator separator = new Separator();

            getChildren().addAll(user, postText, buttons);
        }

        public PostPane(Post p, int user_id) {
            super();
            System.out.println("NEW POST_PANE " + p.first_name + " " + p.last_name + " " + user_id);
            HBox user = new HBox();
            ImageView userIcon = new ImageView(); // TODO: 02.06.2020 add picture_url
            Text userName = new Text(p.first_name + " " + p.last_name);
            user.getChildren().addAll(userIcon, userName);
            user.setVisible(true);


            Text postText = new Text(p.post_text);


            HBox buttons = new HBox();
            Button like = new Button("like");
            Button repost = new Button("repost");
            buttons.getChildren().addAll(like, repost);
            if(p.user_id == user_id) {
                Button delete = new Button("delete");
                delete.setOnMouseClicked(mouseEvent -> {
                    Main.delMessage(p);
                });
                buttons.getChildren().add(delete);
            }

            Separator separator = new Separator();

            getChildren().addAll(user, postText, buttons, separator);
        }
    }
}
