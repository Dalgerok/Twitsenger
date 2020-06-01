package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.input.MouseEvent;
import javafx.scene.text.Text;
import main.java.org.Tools.RegisterInfo;


public class RegisterSceneController {
    @FXML public TextField firstNameField;
    @FXML public TextField lastNameField;
    @FXML public TextField registerEmail;
    @FXML public PasswordField registerPassword;
    @FXML public TextField registerPassword2;
    @FXML public DatePicker birthadayField;

    @FXML public ToggleGroup GroupGender;
    @FXML public RadioButton maleButton;
    @FXML public RadioButton femaleButton;
    @FXML public RadioButton unspecifiedButton;

    @FXML public ChoiceBox<String> relationshipBox;
    @FXML public Text messageText;

    @FXML
    public void signUpHandler(MouseEvent mouseEvent) {
        if (!registerPassword.getText().equals(registerPassword2.getText())){
            // TODO: 01.06.2020
            messageText.setText("Password");
            messageText.setVisible(true);
            return;
        }
        Main.signUp(new RegisterInfo(firstNameField.getText(), lastNameField.getText(), birthadayField.getValue(),
                registerEmail.getText(),
                relationshipBox.getValue(),
                ((RadioButton)GroupGender.getSelectedToggle()).getText(),
                registerPassword.getText()));
    }
}
