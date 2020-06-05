package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import org.twitterissimo.tools.SearchProfileFilter;
import org.twitterissimo.tools.ServerUser;

import java.util.ArrayList;


public class SearchSceneController {
    public ListView<Main.FriendBox> searchResults;
    public TextField city;
    public TextField country;
    public TextField lastName;
    public TextField firstName;
    public AnchorPane searchPane;

    public void searchButtonHandler(MouseEvent mouseEvent) {
        Main.sendObject(new SearchProfileFilter(firstName.getText(), lastName.getText(), country.getText(), city.getText()));
    }

    public void clearResults() {
        searchResults.setItems(FXCollections.observableArrayList());
    }

    public void updateSearchResults(ArrayList<ServerUser> list) {
        ObservableList<Main.FriendBox> results = FXCollections.observableArrayList();
        for (ServerUser su : list){
            results.add(new Main.FriendBox(su));
        }
        searchResults.setItems(results);
    }
}
