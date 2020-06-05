package org.twitterissimo.client;

import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.layout.AnchorPane;
import org.twitterissimo.tools.ConnectionMessage;
import org.twitterissimo.tools.ProfileInfo;
import org.twitterissimo.tools.RegisterInfo;

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


    public void updateProfile(ProfileInfo pi){
        firstNameLabel.setText(pi.first_name);
        lastNameLabel.setText(pi.last_name);
        System.out.println(pi.birthday.toString());
        birthdayDate.setValue(LocalDate.parse(pi.birthday.toString()));
        relationshipPicker.setValue(pi.relationship_status);
        if (pi.gender.equals("Male"))
            maleGender.fire();
        else if (pi.gender.equals("Female"))
            femaleGender.fire();
        else
            unspecifiedGender.fire();
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
                ((RadioButton)genderToggle.getSelectedToggle()).getText(),
                (passwordLabel.getText().equals("") ? Main.user.user_password : passwordLabel.getText()), true));
    }

}
