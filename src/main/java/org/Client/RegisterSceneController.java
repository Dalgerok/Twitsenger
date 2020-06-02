package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.input.MouseEvent;
import javafx.scene.text.Text;
import main.java.org.Tools.ConnectionMessage;
import main.java.org.Tools.RegisterInfo;

import java.net.ConnectException;


public class RegisterSceneController {
    @FXML public TextField firstNameField;
    @FXML public TextField lastNameField;
    @FXML public TextField registerEmail;
    @FXML public PasswordField registerPassword;
    @FXML public TextField registerPassword2;
    @FXML public DatePicker birthdayField;

    @FXML public ToggleGroup GroupGender;
    @FXML public RadioButton maleButton;
    @FXML public RadioButton femaleButton;
    @FXML public RadioButton unspecifiedButton;

    @FXML public ChoiceBox<String> relationshipBox;
    @FXML public Text messageText;

    @FXML
    public void signUpHandler(MouseEvent mouseEvent) {
        if(firstNameField.getText().isEmpty()){
            messageText.setText("Enter first name");
            messageText.setVisible(true);
            return;
        }
        if(lastNameField.getText().isEmpty()){
            messageText.setText("Enter last name");
            messageText.setVisible(true);
            return;
        }
        if(birthdayField.getValue() == null){
            messageText.setText("Enter your birthday");
            messageText.setVisible(true);
            return;
        }
        if(registerEmail.getText().isEmpty()){
            messageText.setText("Enter email");
            messageText.setVisible(true);
            return;
        }
        if(registerPassword.getText().isEmpty()){
            messageText.setText("Enter password");
            messageText.setVisible(true);
            return;
        }
        if (!registerPassword.getText().equals(registerPassword2.getText())){
            messageText.setText("Password");
            messageText.setVisible(true);
            return;
        }
        ConnectionMessage o = Main.signUp(new RegisterInfo(firstNameField.getText(), lastNameField.getText(), birthdayField.getValue(),
                registerEmail.getText(),
                relationshipBox.getValue(),
                ((RadioButton)GroupGender.getSelectedToggle()).getText(),
                registerPassword.getText()));
        System.out.println("GOT " + o);
        if(ConnectionMessage.BAD_BIRTHDAY.equals(o)){
            messageText.setText("You must be 13 years old to register");
            messageText.setVisible(true);
            return;
        }
        if(ConnectionMessage.BAD_EMAIL.equals(o)){
            messageText.setText("This email is already taken");
            messageText.setVisible(true);
            return;
        }
        messageText.setText("Unable to connect to server");
        messageText.setVisible(true);
    }

    public void returnHandler(MouseEvent mouseEvent) {
        Main.setStartScene();
    }
}
