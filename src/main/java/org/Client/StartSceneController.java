package main.java.org.Client;

import javafx.fxml.FXML;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;

public class StartSceneController {
    @FXML public TextField loginEmail;
    @FXML public TextField loginPassword;

    @FXML
    public void loginButtonHandler(MouseEvent mouseEvent) {
    }
    @FXML
    public void registerButtonHandler(MouseEvent mouseEvent) {
        Main.setRegisterScene();
    }

}
