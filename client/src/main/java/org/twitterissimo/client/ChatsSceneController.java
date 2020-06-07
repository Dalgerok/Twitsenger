package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.control.ListView;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import org.twitterissimo.tools.ChatItem;
import org.twitterissimo.tools.ServerUser;

import java.io.Serializable;

public class ChatsSceneController {
    @FXML public AnchorPane chatsPane;
    @FXML public ListView chatsView;

    public void clearChats() {
        chatsView.setItems(FXCollections.observableArrayList());
    }

    public static class ChatBox extends HBox{
        ServerUser otherUser;
        public ChatBox(ChatItem chatItem){
            super();
            setOnMouseClicked(event -> Main.setMessagesScene(otherUser.user_id));

        }
    }
}
