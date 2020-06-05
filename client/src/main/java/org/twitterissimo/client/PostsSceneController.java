package org.twitterissimo.client;

import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.scene.Node;
import javafx.scene.control.*;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;
import org.twitterissimo.tools.Post;

import java.io.Serializable;
import java.sql.Timestamp;


public class PostsSceneController {
    @FXML public ListView<PostPane> postView;
    @FXML public VBox postsVBox;
    @FXML public TextArea enterMessage;

    public static class PostPane extends VBox implements Serializable {
        public PostPane(Post p, int user_id) {
            super();
            System.out.println("NEW POST_PANE " + p.first_name + " " + p.last_name + " " + user_id);
            HBox user = new HBox();
            ImageView userIcon = new ImageView(); // TODO: 02.06.2020 add picture_url ???
            Hyperlink userName = new Hyperlink(p.first_name + " " + p.last_name);
            userName.setOnMouseClicked(mouseEvent -> {
                Main.setProfileScene(p.user_id);
            });

            user.getChildren().addAll(userIcon, userName);
            user.setVisible(true);


            Text postText = new Text(p.post_text);
            postText.setWrappingWidth(600.0);


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
