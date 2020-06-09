package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.geometry.Pos;
import javafx.scene.control.Button;
import javafx.scene.control.ListView;
import javafx.scene.control.TitledPane;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import javafx.scene.text.Text;
import org.twitterissimo.tools.FriendStatusChange;
import org.twitterissimo.tools.ServerUser;
import org.twitterissimo.tools.UserRequest;

import java.util.ArrayList;
import java.util.Date;

public class FriendsSceneController {
    @FXML public AnchorPane friendsPane;
    @FXML public ListView<Main.FriendBox> friendsView;
    @FXML public ListView<FriendRequestHBox> friendRequestList;
    @FXML public TitledPane friendRequestPane;


    public void clearResults() {
        friendsView.setItems(FXCollections.observableArrayList());
    }

    public void updateFriends(ArrayList<ServerUser> list) {
        ObservableList<Main.FriendBox> results = FXCollections.observableArrayList();
        for (ServerUser su : list){
            results.add(new Main.FriendBox(su));
        }
        friendsView.setItems(results);
    }
    public void updateFriendsRequests(ArrayList<UserRequest> list) {
        ObservableList<FriendRequestHBox> arr = FXCollections.observableArrayList();
        for (UserRequest userRequest : list) {
            arr.add(new FriendRequestHBox(userRequest));
        }
        friendRequestList.setItems(arr);
    }

    public void updateButtons(){
        if (friendsView != null){
            for (Main.FriendBox fb : friendsView.getItems()){
                fb.updateButtons();
            }
        }
    }

    public class FriendRequestHBox extends HBox {
        Text txt = new Text();
        Button button = new Button();
        Button button2 = new Button();
        Button button3 = new Button();
        public FriendRequestHBox(UserRequest userRequest) {

            ServerUser user =  userRequest.from_whom;
            txt.setText(user.first_name + " " + user.last_name);
            button.setText("add");
            button.setOnAction(actionEvent -> {
                Main.sendObject(new FriendStatusChange(Main.user, user, FriendStatusChange.FriendQuery.ADD));
                Main.setFriendsScene(Main.user.user_id, true);
            });
            button2.setText("decline");
            button2.setOnAction(actionEvent -> {
                Main.sendObject(new FriendStatusChange(user, Main.user, FriendStatusChange.FriendQuery.REMOVE_REQUEST));
                Main.setFriendsScene(Main.user.user_id, true);
            });
            button3.setText("view profile");
            button3.setOnAction(actionEvent -> Main.setProfileScene(user.user_id));
            this.setAlignment(Pos.CENTER);
            this.setSpacing(10);
            this.getChildren().addAll(txt, button3, button, button2);
        }
    }

    public String dateWTime(Date date){
        if (date == null)
            return "...";
        return date.toString().substring(0, 10);
    }

}
