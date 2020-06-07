package org.twitterissimo.client;

import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.scene.Node;
import javafx.scene.control.*;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.text.Font;
import javafx.scene.text.Text;
import org.twitterissimo.tools.Post;

import java.io.Serializable;
import java.sql.SQLOutput;
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
            ImageView userIcon = new ImageView(); // TODO: 02.06.2020 ADD PICTURE_URL ???
            Hyperlink userName = new Hyperlink(p.first_name + " " + p.last_name);
            userName.setOnMouseClicked(mouseEvent -> {
                Main.setProfileScene(p.user_id);
            });

            user.getChildren().addAll(userIcon, userName);
            user.setVisible(true);

            HBox texts = new HBox();
            Text postText = new Text(p.post_text);
            postText.setWrappingWidth(600.0);
            texts.getChildren().add(postText);
            if(p.repost != null){
                if(p.reposted_from == 0){
                    System.out.println("IMPOSSIBLE BRO, REPOST BUT NOT REPOSTED FROM");
                    System.exit(0);
                }
                Text repostedText = new Text(p.repost.post_text); // TODO: 06.06.2020 WHOLE POST, NOT ONLY TEXT
                repostedText.setFont(Font.font(3));
                texts.getChildren().add(repostedText);
            }


            HBox buttons = new HBox();
            Button like = new Button("like");
            Button repost = new Button("repost");
            repost.setOnMouseClicked(mouseEvent -> {
                // TODO: 07.06.2020  
            });
            buttons.getChildren().addAll(like, repost);
            if(p.user_id == user_id) {
                Button delete = new Button("delete");
                delete.setOnMouseClicked(mouseEvent -> {
                    Main.delMessage(p);
                });
                buttons.getChildren().add(delete);
            }
            Separator separator = new Separator();
            getChildren().addAll(user, texts, buttons, separator);
        }
    }
}
