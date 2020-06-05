package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.layout.AnchorPane;
import javafx.scene.text.Text;
import org.twitterissimo.tools.*;

import java.time.LocalDate;

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
    @FXML public ListView<Text> schoolList;
    @FXML public ListView<Text> universityList;
    @FXML public ListView<Text> jobsList;


    public void updateProfile(ProfileInfo pi){
        firstNameLabel.setText(pi.first_name);
        lastNameLabel.setText(pi.last_name);
        System.out.println(pi.birthday.toString());
        birthdayDate.setValue(LocalDate.parse(pi.birthday.toString()));
        pictureUrlLabel.setText(pi.picture_url);
        relationshipPicker.setValue(pi.relationship_status);
        if (pi.gender.equals("Male"))
            maleGender.fire();
        else if (pi.gender.equals("Female"))
            femaleGender.fire();
        else
            unspecifiedGender.fire();
        ObservableList<Text> schools = FXCollections.observableArrayList();
        ObservableList<Text> univers = FXCollections.observableArrayList();
        ObservableList<Text> jobs = FXCollections.observableArrayList();
        for (UserFacility userfacility : pi.facilities){
            //if (facility.type.equals("School"))schools.add(new Text(facility.name + ", " + facility.location.makeString()));
            //if (facility.type.equals("University"))univers.add(new Text(facility.name + ", " + facility.location.makeString()));
            //if (facility.type.equals("Work"))jobs.add(new Text(facility.name + ", " + facility.location.makeString()));
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
        Main.editProfileUpdate(new RegisterInfo(firstNameLabel.getText(), lastNameLabel.getText(), birthdayDate.getValue(),
                Main.user.email,
                relationshipPicker.getValue(),
                ((RadioButton)genderToggle.getSelectedToggle()).getText(), pictureUrlLabel.getText(),
                (passwordLabel.getText().equals("") ? Main.user.user_password : passwordLabel.getText()), true));
    }

}
