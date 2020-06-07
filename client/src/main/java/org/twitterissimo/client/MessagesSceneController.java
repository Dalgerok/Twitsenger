package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.geometry.Pos;
import javafx.scene.control.*;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.KeyCode;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.StackPane;
import javafx.scene.text.Text;
import org.twitterissimo.tools.ClientPlace;
import org.twitterissimo.tools.Message;
import org.twitterissimo.tools.ServerUser;
import org.twitterissimo.tools.UserMessages;

public class MessagesSceneController {
    @FXML public AnchorPane messagesPane;

    @FXML public ImageView profileImage;
    @FXML public StackPane circleAvatar;
    @FXML public Text firstNameAvatar;
    @FXML public Text lastNameAvatar;

    @FXML public Hyperlink nameMessages;

    @FXML public ListView<MessageBox> messagesView;
    @FXML public TextArea enterMessage;

    ServerUser otherUser;
    public void updateMessages(UserMessages um){
        if (um.reason.equals("you asked") || (um.reason.equals("just update") && Main.clientPlace == ClientPlace.MESSAGES_SCENE && otherUser.user_id == um.other.user_id)){
            ObservableList<MessageBox> messages = FXCollections.observableArrayList();
            for (Message message : um.messages){
                messages.add(new MessageBox(message));
            }
            messagesView.setItems(messages);
            if (um.reason.equals("you asked"))messagesView.scrollTo(messages.size() - 1);
        }
        if (um.reason.equals("you asked")){
            otherUser = um.other;
            nameMessages.setText(otherUser.first_name + " " + otherUser.last_name);

            boolean badUrl = false;
            Image p = null;
            try {
                p = new Image(otherUser.picture_url);
            } catch (Exception e){
                badUrl = true;
            }
            if (!badUrl && p.getWidth() > 0) {
                profileImage.setImage(p);
                profileImage.setVisible(true);
            }
            else {
                firstNameAvatar.setText(otherUser.first_name.substring(0, 1));
                lastNameAvatar.setText(otherUser.last_name.substring(0, 1));
                circleAvatar.setVisible(true);
            }
        }
    }


    public void initScene(){
        enterMessage.setOnKeyTyped(event -> {
            String string = enterMessage.getText();

            if (string.length() > 250) {
                enterMessage.setText(string.substring(0, 250));
                enterMessage.positionCaret(string.length());
            }
        });
        enterMessage.setOnKeyPressed(ke -> {
            if (ke.getCode().equals(KeyCode.ENTER))
            {
                String s = enterMessage.getText();
                s = s.substring(0, s.length() - 1);
                if(!s.isEmpty()){
                    Main.sendObject(new Message(Main.user, otherUser, s, null));
                }
                enterMessage.clear();
            }
        });
    }

    public void clearMessages() {
        messagesView.setItems(FXCollections.observableArrayList());
    }

    public void hyperlinkHandler(MouseEvent event) {
        Main.setProfileScene(otherUser.user_id);
    }

    public static class MessageBox extends HBox{
        MessageBox(Message message){
            Label time = new Label(message.timestamp.toString().substring(0, 16));
            TextField mLabel = new TextField(message.text);
            mLabel.setEditable(false);

            if (message.from.user_id == Main.user.user_id){
                setAlignment(Pos.CENTER_RIGHT);
                getChildren().addAll(time, mLabel);
            }else {
                setAlignment(Pos.CENTER_LEFT);
                getChildren().addAll(mLabel, time);
            }
        }
    }
}
