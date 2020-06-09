package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.geometry.Pos;
import javafx.scene.control.ComboBox;
import javafx.scene.control.DatePicker;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import javafx.scene.text.Text;
import org.twitterissimo.tools.Facility;
import org.twitterissimo.tools.FacilitySearcher;
import org.twitterissimo.tools.SearchProfileFilter;
import org.twitterissimo.tools.ServerUser;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Date;


public class SearchSceneController {
    public ListView<Main.FriendBox> searchResults;
    public TextField city;
    public TextField country;
    public TextField lastName;
    public TextField firstName;
    public AnchorPane searchPane;
    public TextField facilityName;
    public TextField facilityType;
    public AnchorPane searchFacilityPane;
    public ComboBox<String> typeChooser;
    public TextField facilityNameField;
    public ListView<FacilitySearch> facilitiesView;
    public DatePicker dateFrom;
    public DatePicker dateTo;
    private Facility facility;

    public void searchButtonHandler(MouseEvent mouseEvent) {
        int facId = 0;
        if (facility != null)facId = facility.facility_id;
        Date dateF = null;
        if (dateFrom.getValue() != null){
            LocalDate localDate = dateFrom.getValue();
            Instant instant = Instant.from(localDate.atStartOfDay(ZoneId.systemDefault()));
            dateF = Date.from(instant);
        }

        Date dateT = null;
        if (dateTo.getValue() != null){
            LocalDate localDate = dateTo.getValue();
            Instant instant = Instant.from(localDate.atStartOfDay(ZoneId.systemDefault()));
            dateT = Date.from(instant);
        }
        Main.sendObject(new SearchProfileFilter(firstName.getText(), lastName.getText(), country.getText(), city.getText(), facId, dateF, dateT));
    }

    public void clearResults() {
        searchResults.setItems(FXCollections.observableArrayList());
        searchFacilityPane.setVisible(false);
    }

    public void updateSearchResults(ArrayList<ServerUser> list) {
        ObservableList<Main.FriendBox> results = FXCollections.observableArrayList();
        for (ServerUser su : list){
            if(su.user_id != Main.user.user_id) {
                results.add(new Main.FriendBox(su));
            }
        }
        searchResults.setItems(results);
    }

    public void updateButtons(){
        if (searchResults != null){
            for (Main.FriendBox fb : searchResults.getItems()){
                fb.updateButtons();
            }
        }
    }


    public void closeButtonHandler(MouseEvent event) {
        searchFacilityPane.setVisible(false);
    }

    public void chooseFacilityHandler(MouseEvent event) {
        searchFacilityPane.setVisible(true);
    }

    public void clearFacilityHandler(MouseEvent event) {
        facilityType.clear();
        facilityName.clear();
        dateFrom.setPromptText("From");
        dateTo.setPromptText("To");
    }

    public void updateFacilities(ArrayList<Facility> list) {
        ObservableList<FacilitySearch> facilitySearches = FXCollections.observableArrayList();
        for (Facility facility : list){
            facilitySearches.add(new FacilitySearch(facility));
        }
        facilitiesView.setItems(facilitySearches);
    }

    public void searchFacilitiesButtonHandler(MouseEvent event) {
        Main.sendObject(new FacilitySearcher(typeChooser.getValue(), facilityNameField.getText()));
    }

    public static class FacilitySearch extends HBox{
        Facility facility;
        FacilitySearch(Facility facility){
            this.facility = facility;
            setAlignment(Pos.CENTER);
            Text text = new Text(facility.name + ", " + facility.location.country + ", " + facility.location.city);
            getChildren().add(text);
            setOnMouseClicked(event -> Main.searchSceneController.foundFacility(facility));
        }
    }

    private void foundFacility(Facility facility) {
        this.facility = facility;
        facilityType.setText(facility.type);
        facilityName.setText(facility.name);
        searchFacilityPane.setVisible(false);
    }
}
