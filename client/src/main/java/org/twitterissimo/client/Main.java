package org.twitterissimo.client;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Separator;
import javafx.scene.image.Image;
import javafx.scene.input.KeyCode;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;
import javafx.stage.Stage;
import org.twitterissimo.tools.*;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.net.Socket;
import java.util.ArrayList;

public class Main extends Application{

    static Stage primaryStage;

    static StartSceneController startSceneController;
    static RegisterSceneController registerSceneController;
    static MainSceneController mainSceneController;
    static PostsSceneController postsSceneController;
    static ProfileSceneController profileSceneController;
    static EditProfileSceneController editProfileSceneController;
    static SearchSceneController searchSceneController;
    static FriendsSceneController friendsSceneController;

    static Scene startScene;
    static Scene registerScene;
    static Scene mainScene;
    static ClientPlace clientPlace;

    static ArrayList<ServerUser> friends = new ArrayList<>();

    public static void setRegisterScene() {
        System.out.println("SET REGISTER SCENE");
        primaryStage.setScene(registerScene);
        registerSceneController.messageText.setVisible(false);
    }

    public static void setStartScene() {
        System.out.println("SET START SCENE");
        primaryStage.setScene(startScene);
        startSceneController.textMessage.setVisible(false);
        registerSceneController.messageText.setVisible(false);
    }

    public static void setMainScene() {
        System.out.println("SET MAIN SCENE");
        initMainScene();
        primaryStage.setScene(mainScene);
    }
    public static void setEditProfileScene(int id) {
        setMainScene();
        System.out.println("SET EDITPROFILE SCENE");
        mainSceneController.mainPane.getChildren().setAll(editProfileSceneController.editProfilePane);

        editProfileSceneController.errorText.setVisible(false);
        editProfileSceneController.passwordLabel.setText("");
        editProfileSceneController.passwordConfirmLabel.setText("");
        editProfileSceneController.facilitiesBox.setVisible(false);
        editProfileSceneController.facilityAddingPane.setVisible(false);

        clientPlace = ClientPlace.EDIT_PROFILE_SCENE;
        askForProfileInfo(id);
        // TODO: 02.06.2020
    }
    public static void setProfileScene(int id) {
        setMainScene();
        System.out.println("SET PROFILE SCENE " + id);
        mainSceneController.mainPane.getChildren().setAll(profileSceneController.profilePane);
        profileSceneController.circleAvatar.setVisible(false);
        profileSceneController.profileImage.setVisible(false);
        clientPlace = ClientPlace.PROFILE_SCENE;
        askForProfileInfo(id);
        // TODO: 02.06.2020
    }
    public static void setSearchScene() {
        setMainScene();
        searchSceneController.clearResults();
        System.out.println("SET SEARCH SCENE");
        mainSceneController.mainPane.getChildren().setAll(searchSceneController.searchPane);

        clientPlace = ClientPlace.SEARCH_SCENE;
        // TODO: 02.06.2020
    }
    public static void setFriendsScene(int id) {
        setMainScene();
        askForFriends(id);
        friendsSceneController.clearResults();
        System.out.println("SET FRIENDS SCENE");
        mainSceneController.mainPane.getChildren().setAll(friendsSceneController.friendsPane);

        clientPlace = ClientPlace.FRIENDS_SCENE;
    }
    public static void setPostsScene() {
        setMainScene();
        askForUpdatePostsScene();
        System.out.println("SET POSTS SCENE");
        mainSceneController.mainPane.getChildren().setAll(postsSceneController.postsVBox);

        clientPlace = ClientPlace.POST_SCENE;
    }

    private static final String hostname = "localhost";
    private static final int port = 4321;
    private static Socket clientSocket;
    private static ObjectInputStream in;
    private static ObjectOutputStream out;
    public static ServerUser user;
    public static ConnectionMessage signUp(RegisterInfo registerInfo) {
        if (!connect())return ConnectionMessage.UNABLE_TO_CONNECT;
        if (!sendObject(registerInfo))return ConnectionMessage.UNABLE_TO_CONNECT;
        Object o = getObject();
        if (ConnectionMessage.SIGN_UP.equals(o)){
            o = getObject();
            if(!(o instanceof ServerUser)){
                disconnect();
                return ConnectionMessage.UNABLE_TO_CONNECT;
            }
            user = (ServerUser)o;
            clientPlace = ClientPlace.POST_SCENE;
            startRead();
            setPostsScene();
            return ConnectionMessage.SIGN_UP;
        }else {
            disconnect();
            return (ConnectionMessage)o;
        }
    }

    public static void editProfileUpdate(RegisterInfo registerInfo) {
        System.out.println("I'M HERE");
        if (!sendObject(registerInfo)){
            System.out.println("Can't update profile");
            return;
        }
    }

    public static ConnectionMessage signIn(LoginInfo loginInfo) {
        if (!connect())return ConnectionMessage.UNABLE_TO_CONNECT;
        sendObject(loginInfo);
        Object o = getObject();
        if (ConnectionMessage.SIGN_IN.equals(o)){
            o = getObject();
            if(!(o instanceof ServerUser)){
                disconnect();
                return ConnectionMessage.UNABLE_TO_CONNECT;
            }
            user = (ServerUser)o;
            clientPlace = ClientPlace.POST_SCENE;
            startRead();
            setPostsScene();
            return ConnectionMessage.SIGN_IN;
        }
        else {
            disconnect();
            return (ConnectionMessage)o;
        }
    }

    public static void logout() {
        disconnect();
        setStartScene();
    }

    public static <T extends Serializable> boolean sendObject(T o) {
        System.out.println("Send object " + o);
        if (clientSocket == null || out == null){
            System.out.println("client socket or out is null");
            connect();
        }
        try{
            synchronized (out) {
                out.writeObject(o);
            }
            return true;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }
    public static Object getObject() {
        System.out.println("STREAM ONE " + (in == null));
        if (clientSocket == null || in == null)return null;
        System.out.println("STREAM TWO " + (in == null));
        try{
            Object o;
            System.out.println("IM HERE");
            synchronized (in) {
                o = in.readObject();
            }
            System.out.println("READ " + o);
            return o;
        } catch (IOException | ClassNotFoundException e) {
            e.printStackTrace();
            disconnect();
            //System.exit(0);
        }
        return null;
    }

    private static boolean connect() {
        try{
            clientSocket = new Socket(hostname, port);
            System.out.println(clientSocket.isConnected());
            out = new ObjectOutputStream(clientSocket.getOutputStream());
            in = new ObjectInputStream(clientSocket.getInputStream());
            System.out.println("Established connection");
            return true;
        } catch (IOException e) {
            //e.printStackTrace();
            System.out.println("cannot connect");
            disconnect();
            return false;
        }
    }
    public static void disconnect() {
        //Platform.runLater(Main::setStartScene); IF YOU UNCOMMENT THIS, THEN YOU WILL NOT GET MESSAGES ON START SCENE (BAD EMAIL/PASSWORD)
        stopRead();
        try{
            in = null;
            out = null;
            if (clientSocket != null)clientSocket.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
        System.out.println("DISCONNECTED SUCCESSFULLY");
    }

    public static boolean isMyFriend(int profileId) {
        for (ServerUser su : friends){
            if (su.user_id == profileId)return true;
        }
        return false;
    }


    @Override
    public void start(Stage primaryStage) {
        Main.primaryStage = primaryStage;
        createContent();

        primaryStage.setHeight(820);
        primaryStage.setWidth(820);
        //primaryStage.setResizable(false);
        primaryStage.setOnCloseRequest(windowEvent -> System.exit(0));
        primaryStage.setScene(startScene);
        primaryStage.show();
    }
    private void createContent(){
        initStartScene();
        initRegisterScene();
        initMainScene();
        initPostsScene();
        initProfileScene();
        initEditProfileScene();
        initSearchScene();
        initFriendsScene();
    }
    private void initStartScene() {
        FXMLLoader startLoader = new FXMLLoader(getClass().getResource("/fxml/startScene.fxml"));
        Pane startPane = null;
        try {
            startPane = startLoader.load();
        } catch (Exception e) {
            //e.printStackTrace();
            System.out.println("Can't load startScene");
            System.exit(0);
        }
        startSceneController = startLoader.getController();
        startSceneController.loginEmail.setOnKeyTyped(event -> {
            String string = startSceneController.loginEmail.getText();

            if (string.length() > 100) {
                startSceneController.loginEmail.setText(string.substring(0, 100));
                startSceneController.loginEmail.positionCaret(string.length());
            }
        });
        startSceneController.loginPassword.setOnKeyTyped(event -> {
            String string = startSceneController.loginPassword.getText();

            if (string.length() > 64) {
                startSceneController.loginPassword.setText(string.substring(0, 64));
                startSceneController.loginPassword.positionCaret(string.length());
            }
        });

        startSceneController.loginButton.setOnKeyPressed(ke -> {
            if (ke.getCode().equals(KeyCode.ENTER)) {
                startSceneController.loginButtonHandler(null);
            }
        });
        startPane.setOnKeyPressed(ke -> {
            if (ke.getCode().equals(KeyCode.ENTER)) {
                startSceneController.loginButtonHandler(null);
            }
        });
        startScene = new Scene(startPane);
    }
    private void initRegisterScene() {
        FXMLLoader registerLoader = new FXMLLoader(getClass().getResource("/fxml/registerScene.fxml"));
        Pane registerPane = null;
        try {
            registerPane = registerLoader.load();
        } catch (IOException e) {
            //e.printStackTrace();
            System.out.println("Can't load registerScene");
            System.exit(0);
        }
        registerSceneController = registerLoader.getController();
        registerSceneController.firstNameField.setOnKeyTyped(event -> {
            String string = registerSceneController.firstNameField.getText();

            if (string.length() > 32) {
                registerSceneController.firstNameField.setText(string.substring(0, 32));
                registerSceneController.firstNameField.positionCaret(string.length());
            }
        });
        registerSceneController.lastNameField.setOnKeyTyped(event -> {
            String string = registerSceneController.lastNameField.getText();

            if (string.length() > 32) {
                registerSceneController.lastNameField.setText(string.substring(0, 32));
                registerSceneController.lastNameField.positionCaret(string.length());
            }
        });
        registerSceneController.registerEmail.setOnKeyTyped(event -> {
            String string = registerSceneController.registerEmail.getText();

            if (string.length() > 100) {
                registerSceneController.registerEmail.setText(string.substring(0, 100));
                registerSceneController.registerEmail.positionCaret(string.length());
            }
        });
        registerSceneController.registerPassword.setOnKeyTyped(event -> {
            String string = registerSceneController.registerPassword.getText();

            if (string.length() > 64) {
                registerSceneController.registerPassword.setText(string.substring(0, 64));
                registerSceneController.registerPassword.positionCaret(string.length());
            }
        });
        registerScene = new Scene(registerPane);
    }
    private static void initMainScene(){
        FXMLLoader mainLoader = new FXMLLoader(Main.class.getResource("/fxml/mainScene.fxml"));
        Pane mainPane = null;
        try {
            mainPane = mainLoader.load();
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Can't load mainScene");
            System.exit(0);
        }
        mainSceneController = mainLoader.getController();
        mainScene = new Scene(mainPane);
    }
    private static void initProfileScene(){
        FXMLLoader mainLoader = new FXMLLoader(Main.class.getResource("/fxml/profileScene.fxml"));
        Pane profilePane = null;
        try {
            profilePane = mainLoader.load();
        } catch (Exception e) {
            //e.printStackTrace();
            System.out.println("Can't load profileScene");
            System.exit(0);
        }
        profileSceneController = mainLoader.getController();
    }
    private void initEditProfileScene(){
        FXMLLoader editProfileLoader = new FXMLLoader(Main.class.getResource("/fxml/editProfileScene.fxml"));
        Pane editProfilePane = null;
        try {
            editProfilePane = editProfileLoader.load();
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Can't load editProfileScene");
            System.exit(0);
        }
        editProfileSceneController = editProfileLoader.getController();
    }

    private static void initSearchScene(){
        FXMLLoader mainLoader = new FXMLLoader(Main.class.getResource("/fxml/searchScene.fxml"));
        Pane searchPane = null;
        try {
            searchPane = mainLoader.load();
        } catch (Exception e) {
            //e.printStackTrace();
            System.out.println("Can't load searchScene");
            System.exit(0);
        }
        searchSceneController = mainLoader.getController();
    }
    private static void initFriendsScene(){
        FXMLLoader mainLoader = new FXMLLoader(Main.class.getResource("/fxml/friendsScene.fxml"));
        Pane friendsPane = null;
        try {
            friendsPane = mainLoader.load();
        } catch (Exception e) {
            //e.printStackTrace();
            System.out.println("Can't load friendsScene");
            System.exit(0);
        }
        friendsSceneController = mainLoader.getController();
    }
    private static void initPostsScene(){
        FXMLLoader postsLoader = new FXMLLoader(Main.class.getResource("/fxml/postsScene.fxml"));
        VBox kek = null;
        try{
            kek = postsLoader.load();
        } catch (Exception e){
            e.printStackTrace();
            System.out.println("Can't load postsScene");
            System.exit(0);
        }
        postsSceneController = postsLoader.getController();
        postsSceneController.enterMessage.setOnKeyTyped(event -> {
            String string = postsSceneController.enterMessage.getText();

            if (string.length() > 250) {
                postsSceneController.enterMessage.setText(string.substring(0, 250));
                postsSceneController.enterMessage.positionCaret(string.length());
            }
        });
        postsSceneController.enterMessage.setOnKeyPressed(ke -> {
            if (ke.getCode().equals(KeyCode.ENTER))
            {
                String s = postsSceneController.enterMessage.getText();
                s = s.substring(0, s.length() - 1);
                if(!s.isEmpty()){
                    sendMessage(s);
                }
                postsSceneController.enterMessage.clear();
            }
        });
    }
    public static void askForUpdatePostsScene(){
        System.out.println("ASK FOR UPDATE POSTS SCENE");
        sendObject(ConnectionMessage.GET_POSTS);
    }
    public static void updatePostsScene(ArrayList<Post> list){
        System.out.println("UPDATE POSTS SCENE");
        ObservableList<PostsSceneController.PostPane> l = FXCollections.observableArrayList();
        for(Post p : list){
            l.add(new PostsSceneController.PostPane(p, user.user_id));
        }
        postsSceneController.postView.setItems(l);
    }
    private static void updateProfileScene(ProfileInfo pi) {
        System.out.println("UPDATE PROFILE SCENE");
        profileSceneController.updateProfile(pi);
    }
    private static void updateEditProfileScene(ProfileInfo pi){
        editProfileSceneController.updateProfile(pi);
    }
    public static void askForProfileInfo(int id){
        System.out.println("ASK FOR USER INFO");
        sendObject(new ProfileRequest(id));
    }
    public static void askForFriends(int id){
        System.out.println("ASK FOR USER INFO");
        sendObject(new GetUserFriends(id));
    }

    private static void sendMessage(String s) {
        System.out.println("SEND MESSAGE " + s);
        sendObject(ConnectionMessage.NEW_POST);
        sendObject(new Post(s));
        askForUpdatePostsScene();
    }
    public static void delMessage(Post p) {
        System.out.println("DEL MESSAGE " + p);
        sendObject(ConnectionMessage.DEL_POST);
        sendObject(p);

        sendObject(new ProfileRequest(user.user_id));
        askForUpdatePostsScene();
    }

    public static void getIdByLocation(String s){
        sendObject(ConnectionMessage.ID_BY_LOCATION);
        sendObject(s);
    }

    public static void UserToFacility(UserFacility userFacility){
        sendObject(userFacility);
    }

    public static void addFacility(Facility facility) {
        sendObject(facility);
    }


    public static void main(String[] args) {
        Main main = new Main();
        launch(args);
    }
    private static ObjectReader reader = null;

    private static void startRead() {
        reader = new ObjectReader();
        reader.start();
    }
    private static void stopRead(){
        System.out.println("Stop read");
        if (reader != null && !reader.isInterrupted()){
            System.out.println("Interrupting...  DSFDVRWWFDWWRDWGR");
            reader.interrupt();
        }
    }
    public static class ObjectReader extends Thread {
        @Override
        public void run() {
            System.out.println("STARTED READING");
            while (!isInterrupted()) {
                try {
                    System.out.println("start receiving");
                    Object obj;
                    synchronized (in){
                        obj = getObject();
                    }
                    System.out.println("RECEIVED " + obj);
                    if (obj instanceof ConnectionMessage){
                        if (obj.equals(ConnectionMessage.UPDATE_POSTS)){
                            if (clientPlace.equals(ClientPlace.PROFILE_SCENE))askForProfileInfo(profileSceneController.profileId);
                            if (clientPlace.equals(ClientPlace.POST_SCENE))askForUpdatePostsScene();
                        }
                        if (obj.equals(ConnectionMessage.UPDATED_PROFILE)){
                            System.out.println("KEK IM UPDATING PROFILE");
                            Object obj2;
                            obj2 = getObject();
                            if (!(obj2 instanceof ServerUser)){
                                System.out.println("SOMETHING WRONG IN editProfileUpdate");
                                continue;
                            }
                            user = (ServerUser)obj2;
                            Platform.runLater(() -> setProfileScene(user.user_id));
                            continue;
                        }
                        else if (obj.equals(ConnectionMessage.BAD_BIRTHDAY)){
                            Platform.runLater(() -> {
                                editProfileSceneController.errorText.setText("You must be at least 13 years old to register");
                                editProfileSceneController.errorText.setVisible(true);
                            });
                            continue;
                        }
                        else if (obj.equals(ConnectionMessage.BAD_PASSWORD)){
                            Platform.runLater(() -> {
                                editProfileSceneController.errorText.setText("This email is already taken");
                                editProfileSceneController.errorText.setVisible(true);
                            });
                            continue;
                        }
                    }
                    if (obj instanceof ArrayList){
                        Object o = ((ArrayList) obj).get(0);
                        ((ArrayList) obj).remove(0);
                        if (o instanceof Facility) Platform.runLater(() -> editProfileSceneController.updateSearchResult((ArrayList<Facility>)obj));
                        if (o instanceof Post)Platform.runLater(() -> updatePostsScene((ArrayList<Post>)obj));
                        if (o instanceof ServerUser) System.out.println(((ServerUser) o).first_name);
                        if (o instanceof ServerUser && ((ServerUser) o).first_name.equals("search"))Platform.runLater(() -> searchSceneController.updateSearchResults((ArrayList<ServerUser>)obj));
                        if (o instanceof ServerUser && ((ServerUser) o).first_name.equals("friends"))Platform.runLater(() -> friendsSceneController.updateFriends((ArrayList<ServerUser>)obj));
                        if (o instanceof ServerUser && ((ServerUser) o).first_name.equals("myFriends")){
                            friends.clear();
                            friends.addAll((ArrayList<ServerUser>)obj);
                            if (clientPlace.equals(ClientPlace.PROFILE_SCENE)){
                                Platform.runLater(() -> profileSceneController.updateButtons());
                                askForProfileInfo(profileSceneController.profileId);
                            }
                            if (clientPlace.equals(ClientPlace.FRIENDS_SCENE)){
                                Platform.runLater(() -> friendsSceneController.updateButtons());
                            }
                            if (clientPlace.equals(ClientPlace.SEARCH_SCENE)){
                                Platform.runLater(() -> searchSceneController.updateButtons());
                            }
                        }
                    }
                    if (obj instanceof ProfileInfo) {
                        if (clientPlace.equals(ClientPlace.PROFILE_SCENE))
                            Platform.runLater(() -> updateProfileScene((ProfileInfo)obj));
                        if (clientPlace.equals(ClientPlace.EDIT_PROFILE_SCENE))
                            Platform.runLater(() -> updateEditProfileScene((ProfileInfo)obj));
                    }
                    if (obj instanceof Integer) {
                        int x = (Integer)obj;
                        if (clientPlace.equals(ClientPlace.EDIT_PROFILE_SCENE)){
                            if (x % 2 == 0)
                                editProfileSceneController.locationId = x/2;
                            else {
                                editProfileSceneController.facilityId = x/2;
                            }
                        }
                    }
                } catch (Exception e) {
                    System.out.println("SERVER DOWN");
                    e.printStackTrace(); // TODO: 06.06.2020 COMMENT THIS LINE
                    disconnect();
                }
            }
            //System.out.println("STOPPED READING");
        }

    }



    public static class FriendBox extends HBox {
        private ServerUser user;
        private final Text fName;
        private final Text lName;
        private final Button goToProfile;
        private final Button requestFriend;
        public FriendBox(){
            super();
            fName = new Text("First Name");
            lName = new Text("Second Name");
            goToProfile = new Button("Go to profile");
            requestFriend = new Button("Friend request");
            Separator s = new Separator();
            s.setVisible(false);
            getChildren().addAll(fName, s, lName, goToProfile, requestFriend);
        }
        public FriendBox(ServerUser us){
            this();
            this.user = us;
            updateButtons();
            fName.setText(user.first_name);
            lName.setText(user.last_name);
            goToProfile.setOnMouseClicked(event -> Main.setProfileScene(user.user_id));
            requestFriend.setOnMouseClicked(event -> {
                if (Main.isMyFriend(user.user_id)){
                    Main.sendObject(new FriendStatusChange(Main.user, user, FriendStatusChange.FriendQuery.REMOVE));
                }else{
                    Main.sendObject(new FriendStatusChange(Main.user, user, FriendStatusChange.FriendQuery.ADD));
                }
                // TODO: 04.06.2020
            });
        }
        public void updateButtons() {
            if (user.user_id == Main.user.user_id){
                requestFriend.setVisible(false);
            }else {
                requestFriend.setVisible(true);
                if (Main.isMyFriend(user.user_id)){
                    requestFriend.setText("Unfriend");
                }else {
                    requestFriend.setText("Add friend");
                }
            }
        }
    }
}