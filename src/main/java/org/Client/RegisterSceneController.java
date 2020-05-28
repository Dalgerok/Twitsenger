package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.input.MouseEvent;

public class RegisterSceneController {
    @FXML public TextField firstNameField;
    @FXML public TextField secondNameField;
    @FXML public TextField registerEmail;
    @FXML public PasswordField registerPassword;
    @FXML public TextField registerPassword2;
    @FXML public DatePicker birthadayField;
    @FXML public RadioButton maleButton;
    @FXML public ToggleGroup GroupGender;
    @FXML public RadioButton femaleButton;

    @FXML
    public void signUpHandler(MouseEvent mouseEvent) {
    }
}
