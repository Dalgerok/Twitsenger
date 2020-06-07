package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.*;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import javafx.scene.text.Text;
import org.twitterissimo.tools.*;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Date;
import java.util.concurrent.atomic.AtomicInteger;

public class EditProfileSceneController {
    @FXML public Label errorText;
    @FXML public AnchorPane editProfilePane;
    @FXML public TextField firstNameLabel;
    @FXML public TextField lastNameLabel;
    @FXML public DatePicker birthdayDate;
    @FXML public ComboBox<String> relationshipPicker;
    @FXML public RadioButton maleGender;
    @FXML public RadioButton femaleGender;
    @FXML public RadioButton unspecifiedGender;
    @FXML public PasswordField passwordLabel;
    @FXML public PasswordField passwordConfirmLabel;
    @FXML public ToggleGroup genderToggle;
    @FXML public TextField pictureUrlLabel;
    @FXML public ListView<DeleteHBox> schoolList;
    @FXML public ListView<DeleteHBox> universityList;
    @FXML public ListView<DeleteHBox> jobsList;
    @FXML public AnchorPane facilitiesBox;
    @FXML public AnchorPane facilityAddingPane;
    @FXML public Label addYourOwnLabel;
    @FXML public TextField searchFacilityLabel;
    @FXML public Label searchForLabel;
    @FXML public TextField addYourOwnTextField;
    @FXML public ListView<MyHBox> facilitySearchList;
    @FXML public DatePicker dateFromPicker;
    @FXML public DatePicker dateToPicker;
    @FXML public TextField descriptionTextField;
    @FXML public TextField addYourOwnLocation;
    @FXML public TextField locationTextField;

    public String currentSearchType;

    //public volatile int locationId;
    public AtomicInteger locationId = new AtomicInteger();
    public AtomicInteger facilityId = new AtomicInteger();

    public void updateProfile(ProfileInfo pi){
        firstNameLabel.setText(pi.first_name);
        lastNameLabel.setText(pi.last_name);
        System.out.println(pi.birthday.toString());
        birthdayDate.setValue(LocalDate.parse(pi.birthday.toString()));
        if (!pi.picture_url.equals("null"))
            pictureUrlLabel.setText(pi.picture_url);
        else
            pictureUrlLabel.setText("");
        relationshipPicker.setValue(pi.relationship_status);
        if (pi.location != null)
            locationTextField.setText(pi.location.country + ":" + pi.location.city);
        else
            locationTextField.setText("");
        if (pi.gender.equals("Male"))
            maleGender.fire();
        else if (pi.gender.equals("Female"))
            femaleGender.fire();
        else
            unspecifiedGender.fire();
        ObservableList<DeleteHBox> schools = FXCollections.observableArrayList();
        ObservableList<DeleteHBox> univers = FXCollections.observableArrayList();
        ObservableList<DeleteHBox> jobs = FXCollections.observableArrayList();
        for (UserFacility userfacility : pi.facilities){
            Facility facility = userfacility.facility;
            if (facility.type.equals("School")){
                schools.add(new DeleteHBox(userfacility));
            }
            if (facility.type.equals("University")){
                univers.add(new DeleteHBox(userfacility));
            }
            if (facility.type.equals("Work")){
                jobs.add(new DeleteHBox(userfacility));
            }
        }
        schoolList.setItems(schools);
        universityList.setItems(univers);
        jobsList.setItems(jobs);
    }

    @FXML
    public void savePreferencesEdit(){

        if(firstNameLabel.getText().isEmpty()){
            errorText.setText("Enter first name");
            errorText.setVisible(true);
            return;
        }
        if(lastNameLabel.getText().isEmpty()){
            errorText.setText("Enter last name");
            errorText.setVisible(true);
            return;
        }
        if(birthdayDate.getValue() == null){
            errorText.setText("Enter your birthday");
            errorText.setVisible(true);
            return;
        }
        if (!passwordLabel.getText().equals("")){
            if (!passwordConfirmLabel.getText().equals(passwordLabel.getText())){
                errorText.setText("Passwords don't match");
                errorText.setVisible(true);
                return;
            }
        }
        if (!locationTextField.getText().equals("")) {
            String[] arr = locationTextField.getText().split(":");
            if (arr.length != 2) {
                errorText.setText("Wrong location format");
                errorText.setVisible(true);
                return;
            }
        }
        locationId.set(-1);
        if (!locationTextField.getText().equals("")) {
            Main.getIdByLocation(locationTextField.getText());
            locationId.set(0);
            while(locationId.get() == 0) {

            }
            if (locationId.get() == -1) {
                String[] arr = locationTextField.getText().split(":");
                Main.addLocation(new Location(arr[0], arr[1], 0));
                locationId.set(0);
                while(locationId.get() == 0) {

                }
            }
        }


        RegisterInfo registerInfo = new RegisterInfo(firstNameLabel.getText(), lastNameLabel.getText(), birthdayDate.getValue(),
                Main.user.email,
                relationshipPicker.getValue(),
                ((RadioButton)genderToggle.getSelectedToggle()).getText(), pictureUrlLabel.getText(),
                (passwordLabel.getText().equals("") ? Main.user.user_password : passwordLabel.getText()), true);
        registerInfo.setLocation_id(locationId.get());

        Main.editProfileUpdate(registerInfo);
    }

    @FXML
    public void editFacilitiesButton() {
        facilitiesBox.setVisible(true);
    }

    @FXML
    public void closeFacilitiesButton() {
        facilitiesBox.setVisible(false);
    }
    @FXML
    public void addSchoolFacility() {
        searchForLabel.setText("Search for schools");
        addYourOwnLabel.setText("or add new school");
        searchForFacility("School");
    }
    @FXML
    public void addUniversityFacility() {
        searchForLabel.setText("Search for universities");
        addYourOwnLabel.setText("or add new university");
        searchForFacility("University");
    }
    @FXML
    public void addJobFacility() {
        searchForLabel.setText("Search for jobs");
        addYourOwnLabel.setText("or add new job");
        searchForFacility("Work");
    }
    @FXML
    public void addAndSelectButton() {
        String[] arr = addYourOwnLocation.getText().split(":");
        if (arr.length != 2)
            return;
        locationId.set(0);
        Main.getIdByLocation(addYourOwnLocation.getText());
        while(locationId.get() == 0) {

        }
        if (locationId.get() == -1){
            Main.addLocation(new Location(arr[0], arr[1], 0));
            locationId.set(0);
            while(locationId.get() == 0) {

            }
        }
        System.out.println(locationId);
        facilityId.set(0);
        Main.addFacility(new Facility(addYourOwnTextField.getText(), new Location(arr[0], arr[1], locationId.get()), currentSearchType, 0));
        while(facilityId.get() == 0) {

        }

        LocalDate localDate = dateFromPicker.getValue();
        Instant instant = Instant.from(localDate.atStartOfDay(ZoneId.systemDefault()));
        Date dateFrom = Date.from(instant);
        Date dateTo = null;
        if (dateToPicker.getValue() != null){
            localDate = dateToPicker.getValue();
            instant = Instant.from(localDate.atStartOfDay(ZoneId.systemDefault()));
            dateTo = Date.from(instant);
        }
        UserFacility sendObj = new UserFacility(Main.user.user_id, facilityId.get(), dateFrom, dateTo, descriptionTextField.getText());
        sendObj.setAdd(true);
        Main.UserToFacility(sendObj);
        Main.askForProfileInfo(Main.user.user_id);
        facilityAddingPane.setVisible(false);
    }
    @FXML
    public void searchButton() {
        Main.sendObject(new FacilitySearcher(currentSearchType, searchFacilityLabel.getText()));
    }
    @FXML
    public void closeFacilitySearchButton() {
        facilityAddingPane.setVisible(false);
    }

    public void searchForFacility(String type){
        currentSearchType = type;
        searchFacilityLabel.setText("");
        addYourOwnTextField.setText("");
        facilitySearchList.setItems(null);
        dateFromPicker.setValue(null);
        dateToPicker.setValue(null);
        descriptionTextField.setText("");
        addYourOwnLocation.setText("");
        facilityAddingPane.setVisible(true);
    }

    public class MyHBox extends HBox {
        Button button = new Button();
        Text text;
        public MyHBox(Facility facility){
            button.setText("+");
            //button.setPadding(new Insets(0, 5, 0, 0));
            text = new Text(facility.name + " " + facility.location.makeString());
            this.setAlignment(Pos.CENTER);
            this.getChildren().addAll(button, text);
            this.setSpacing(5);
            button.setOnAction(actionEvent -> {
                LocalDate localDate = dateFromPicker.getValue();
                Instant instant = Instant.from(localDate.atStartOfDay(ZoneId.systemDefault()));
                Date dateFrom = Date.from(instant);
                Date dateTo = null;
                if (dateToPicker.getValue() != null){
                    localDate = dateToPicker.getValue();
                    instant = Instant.from(localDate.atStartOfDay(ZoneId.systemDefault()));
                    dateTo = Date.from(instant);
                }
                UserFacility sendObj = new UserFacility(Main.user.user_id, facility.facility_id, dateFrom, dateTo, descriptionTextField.getText());
                sendObj.setAdd(true);
                Main.UserToFacility(sendObj);
                Main.askForProfileInfo(Main.user.user_id);
                facilityAddingPane.setVisible(false);
            });
        }
    }

    public class DeleteHBox extends HBox {
        Button button = new Button();
        Text text;
        public DeleteHBox(UserFacility userfacility){
            button.setText("-");
            Facility facility = userfacility.facility;
            text = new Text(facility.name + "\n" + dateWTime(userfacility.date_from)+ " - "
                    + dateWTime(userfacility.date_to) + "\n" + userfacility.description + "\n" + facility.location.makeString() );
            this.setAlignment(Pos.CENTER);
            this.getChildren().addAll(button, text);
            this.setSpacing(15);
            button.setOnAction(actionEvent -> {
                UserFacility sendObj = new UserFacility(Main.user.user_id, facility.facility_id, userfacility.date_from);
                sendObj.setAdd(false);
                Main.UserToFacility(sendObj);
                Main.askForProfileInfo(Main.user.user_id);
            });
        }
    }

    public void updateSearchResult(ArrayList<Facility> arr){
        ObservableList<MyHBox> toList = FXCollections.observableArrayList();
        for (Facility facility : arr){
            toList.add(new MyHBox(facility));
        }
        facilitySearchList.setItems(toList);
    }

    public String dateWTime(Date date){
        if (date == null)
            return "...";
        return date.toString().substring(0, 10);
    }


}
