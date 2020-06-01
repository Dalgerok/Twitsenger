package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import main.java.org.Tools.LoginInfo;

public class StartSceneController {
    @FXML public TextField loginEmail;
    @FXML public TextField loginPassword;

    @FXML
    public void loginButtonHandler(MouseEvent mouseEvent) {
        // TODO: 01.06.2020 check
        Main.signIn(new LoginInfo(loginEmail.getText(), loginPassword.getText()));
    }
    @FXML
    public void registerButtonHandler(MouseEvent mouseEvent) {
        Main.setRegisterScene();
    }

}
