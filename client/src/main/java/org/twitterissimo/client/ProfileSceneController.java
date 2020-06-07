package org.twitterissimo.client;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.StackPane;
import javafx.scene.text.Text;
import org.twitterissimo.tools.Facility;
import org.twitterissimo.tools.Post;
import org.twitterissimo.tools.ProfileInfo;
import org.twitterissimo.tools.UserFacility;

import java.util.Date;
import org.twitterissimo.tools.*;


public class ProfileSceneController {
    @FXML public ImageView profileImage;
    @FXML public Label profileLocation;
    @FXML public Label profileRelationship;
    @FXML public Label profileGender;
    @FXML public Label profileBirthday;
    @FXML public Label profileNumPost;
    @FXML public Label profileNumFriend;
    @FXML public ListView<Text> profileSchools;
    @FXML public ListView<Text> profileUnivers;
    @FXML public ListView<Text> profileJobs;
    @FXML public Label profileName;
    @FXML public ListView<PostsSceneController.PostPane> profilePosts;
    @FXML public AnchorPane profilePane;
    @FXML public StackPane circleAvatar;
    @FXML public Text firstNameAvatar;
    @FXML public Text lastNameAvatar;
    @FXML public Button friendRequestButton;
    @FXML public Button sendMessageButton;

    public int profileId;
    ProfileInfo profileInfo;

    public void updateProfile(ProfileInfo pi) {
        this.profileInfo = pi;
        profileId = pi.user_id;
        updateButtons();
        profileName.setText(pi.first_name + " " + pi.last_name);
        profileGender.setText("Gender: " + pi.gender);
        profileBirthday.setText("Birthday: " + pi.birthday.toString());
        profileRelationship.setText("Relationship status: " + pi.relationship_status);
        System.out.println("LOCATION " + pi.location);
        if (pi.location != null){
            profileLocation.setText(pi.location.makeString());
        }
        else {
            profileLocation.setText("Not specified");
        }
        profileNumFriend.setText("Friends: " + pi.numFriends);
        profileNumPost.setText("Posts: " + pi.numPosts);

        ObservableList<Text> schools = FXCollections.observableArrayList();
        ObservableList<Text> univers = FXCollections.observableArrayList();
        ObservableList<Text> jobs = FXCollections.observableArrayList();
        for (UserFacility userfacility : pi.facilities){
            Facility facility = userfacility.facility;
            if (facility.type.equals("School")){
                schools.add(new Text(facility.name + "\n" + dateWTime(userfacility.date_from)+ " - "
                + dateWTime(userfacility.date_to) + "\n" + userfacility.description + "\n" + facility.location.makeString() ));
            }
            if (facility.type.equals("University")){
                univers.add(new Text(facility.name + "\n" + dateWTime(userfacility.date_from) + " - "
                        + dateWTime(userfacility.date_to) + "\n" + userfacility.description + "\n" + facility.location.makeString() ));
            }
            if (facility.type.equals("Work")){
                jobs.add(new Text(facility.name + "\n" + dateWTime(userfacility.date_from) + " - "
                        + dateWTime(userfacility.date_to) + "\n" + userfacility.description + "\n" + facility.location.makeString() ));
            }
        }
        profileSchools.setItems(schools);
        profileUnivers.setItems(univers);
        profileJobs.setItems(jobs);

        ObservableList<PostsSceneController.PostPane> posts = FXCollections.observableArrayList();
        for (Post post : pi.posts){
            posts.add(new PostsSceneController.PostPane(post, Main.user.user_id));
        }
        profilePosts.setItems(posts);
        boolean badUrl = false;
        Image p = null;
        try {
            p = new Image(pi.picture_url);
        } catch (Exception e){
            badUrl = true;
        }
        if (!badUrl && p.getWidth() > 0) {
            profileImage.setImage(p);
            profileImage.setVisible(true);
        }
        else {
            firstNameAvatar.setText(pi.first_name.substring(0, 1));
            lastNameAvatar.setText(pi.last_name.substring(0, 1));
            circleAvatar.setVisible(true);
        }


        // TODO: 03.06.2020  
    }

    public void friendsButtonHandler(MouseEvent event) {
        Main.setFriendsScene(profileId);
    }

    public String dateWTime(Date date){
        if (date == null)
            return "...";
        return date.toString().substring(0, 10);
    }


    public void friendRequestButtonHandler(MouseEvent event) {
        if (Main.isMyFriend(profileId)){
            Main.sendObject(new FriendStatusChange(Main.user, profileInfo, FriendStatusChange.FriendQuery.REMOVE));
        }else{
            Main.sendObject(new FriendStatusChange(Main.user, profileInfo, FriendStatusChange.FriendQuery.ADD));
        }
    }

    public void updateButtons() {
        if (profileId == Main.user.user_id){
            sendMessageButton.setVisible(false);
            friendRequestButton.setVisible(false);
        }else {
            sendMessageButton.setVisible(true);
            friendRequestButton.setVisible(true);
            if (Main.isMyFriend(profileId)){
                friendRequestButton.setText("Unfriend");
            }else {
                friendRequestButton.setText("Add friend");
            }
        }
    }
}
