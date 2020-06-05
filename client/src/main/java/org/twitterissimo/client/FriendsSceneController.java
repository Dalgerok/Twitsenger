package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.control.ListView;
import javafx.scene.layout.AnchorPane;
import org.twitterissimo.tools.ServerUser;

import java.util.ArrayList;

public class FriendsSceneController {
    public AnchorPane friendsPane;
    public ListView<Main.FriendBox> friendsView;


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
    public void updateButtons(){
        if (friendsView != null){
            for (Main.FriendBox fb : friendsView.getItems()){
                fb.updateButtons();
            }
        }
    }
}
