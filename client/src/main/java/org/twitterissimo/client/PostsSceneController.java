package org.twitterissimo.client;

import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;
import org.twitterissimo.tools.Post;

import java.io.Serializable;


public class PostsSceneController {
    @FXML public ListView<PostPane> postView;
    @FXML public VBox postsVBox;
    @FXML public TextArea enterMessage;
    @FXML public ToggleGroup TOGGLE_GROUP;
    @FXML public RadioButton allPostsButton;
    public RadioButton friendsPostsButton;

    public void allPostsButtonHandler(MouseEvent mouseEvent) {
        TOGGLE_GROUP.selectToggle(allPostsButton);
        Main.askForUpdatePostsScene();
    }

    public void friendsPostsButtonHandler(MouseEvent mouseEvent) {
        TOGGLE_GROUP.selectToggle(friendsPostsButton);
        Main.askForUpdatePostsScene();
    }


    public static class PostPane extends VBox implements Serializable {
        int post_id;
        public PostPane(Post p, int user_id) {
            super();
            System.out.println("NEW POST_PANE " + p.first_name + " " + p.last_name + " " + p.post_id);
            post_id = p.post_id;
            HBox user = new HBox();
            ImageView userIcon = new ImageView(); // TODO: 02.06.2020 ADD PICTURE_URL ???
            Hyperlink userName = new Hyperlink(p.first_name + " " + p.last_name);
            userName.setOnMouseClicked(mouseEvent -> {
                Main.setProfileScene(p.user_id);
            });

            user.getChildren().addAll(userIcon, userName);
            user.setVisible(true);

            VBox texts = new VBox();
            Text postText = new Text(p.post_text);
            postText.setWrappingWidth(600.0);
            texts.getChildren().add(postText);
            if(p.repost != null){
                if(p.reposted_from != p.repost.post_id){
                    System.out.println("IMPOSSIBLE BRO, REPOST NOT EQUALS REPOSTED FROM");
                    System.exit(0);
                }
                PostPane repost = new PostPane(p.repost);
                repost.setStyle("-fx-border-color: blue; -fx-border-width: 4;");
                repost.setPrefWidth(500);
                texts.getChildren().add(repost);
            }


            HBox buttons = new HBox();
            buttons.setPrefWidth(600);
            buttons.setPrefHeight(20);
            Button like = new Button("like");
            like.setOnMouseClicked(mouseEvent -> {
                Main.likePost(p); // TODO: 07.06.2020
            });
            Button repost = new Button("repost");
            TextArea repostEnterMessage = new TextArea();
            repostEnterMessage.setPrefWidth(600);
            repostEnterMessage.setPrefHeight(50);
            repostEnterMessage.setWrapText(true);
            repostEnterMessage.setPrefRowCount(2);
            repostEnterMessage.setOnKeyTyped(event -> {
                String string = repostEnterMessage.getText();

                if (string.length() > 250) {
                    repostEnterMessage.setText(string.substring(0, 250));
                    repostEnterMessage.positionCaret(string.length());
                }
            });
            repost.setOnMouseClicked(mouseEvent -> Main.sendRepost(new Post(repostEnterMessage.getText(), p.post_id)));
            buttons.getChildren().addAll(like, repost);
            if(p.user_id == user_id) {
                Button delete = new Button("delete");
                delete.setOnMouseClicked(mouseEvent -> {
                    Main.delMessage(p);
                });
                buttons.getChildren().add(delete);
            }
            Separator separator = new Separator();
            Label likes = new Label("Likes: " + String.valueOf(p.number_of_likes));
            getChildren().addAll(user, texts, buttons, likes, repostEnterMessage);
        }

        public PostPane(Post p) {
            super();
            post_id = p.post_id;
            System.out.println("NEW REPOST POST_PANE " + p.first_name + " " + p.last_name + " " + p.post_id);
            HBox user = new HBox();
            ImageView userIcon = new ImageView(); // TODO: 02.06.2020 ADD PICTURE_URL ???
            Hyperlink userName = new Hyperlink(p.first_name + " " + p.last_name);
            userName.setOnMouseClicked(mouseEvent -> {
                Main.setProfileScene(p.user_id);
            });

            user.getChildren().addAll(userIcon, userName);
            user.setVisible(true);

            VBox texts = new VBox();
            Text postText = new Text(p.post_text);
            postText.setWrappingWidth(500.0);
            texts.getChildren().add(postText);
            Button go_to_post = new Button("Go to post");
            go_to_post.setOnMouseClicked(mouseEvent -> {
                Main.goToPost(p);
            });

            Separator separator = new Separator();
            getChildren().addAll(user, texts, separator, go_to_post);
        }
    }
}
