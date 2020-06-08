package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import org.twitterissimo.tools.ChatItem;
import org.twitterissimo.tools.ServerUser;

import java.util.ArrayList;


public class ChatsSceneController {
    @FXML public AnchorPane chatsPane;
    @FXML public ListView<ChatBox> chatsView;

    public void clearChats() {
        chatsView.setItems(FXCollections.observableArrayList());
    }

    public static class ChatBox extends HBox{
        ServerUser otherUser;
        public ChatBox(ChatItem chatItem){
            super();
            setOnMouseClicked(event -> Main.setMessagesScene(otherUser.user_id));
            otherUser = chatItem.other;
            Label userName = new Label(otherUser.first_name + " " + otherUser.last_name);
            Separator sep1 = new Separator();
            TextArea mLabel = new TextArea(chatItem.message.text);
            mLabel.setPrefHeight(50);
            mLabel.setMaxWidth(300);
            mLabel.setEditable(false);
            mLabel.setWrapText(true);
            Separator sep2 = new Separator();
            Label time = new Label(chatItem.message.timestamp.toString().substring(0, 16));

            getChildren().addAll(userName, sep1, mLabel, sep2, time);
        }
    }

    public void updateChats(ArrayList<ChatItem> list){
        ObservableList<ChatBox> chatItems = FXCollections.observableArrayList();
        for (ChatItem chatItem : list){
            chatItems.add(new ChatBox(chatItem));
        }
        chatsView.setItems(chatItems);
    }
}
