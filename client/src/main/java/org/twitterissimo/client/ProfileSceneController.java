package org.twitterissimo.client;

import javafx.beans.Observable;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.text.Text;
import org.twitterissimo.tools.Facility;
import org.twitterissimo.tools.Post;
import org.twitterissimo.tools.ProfileInfo;

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
    public int profileId;
    public void updateProfile(ProfileInfo pi) {
        profileId = pi.user_id;
        profileName.setText(pi.first_name + " " + pi.last_name);
        profileGender.setText("Gender: " + pi.gender);
        profileBirthday.setText("Birthday: " + pi.birthday.toString());
        profileRelationship.setText("Relationship status: " + pi.relationship_status);
        System.out.println(pi.location);
        if (pi.location != null)profileLocation.setText(pi.location.makeString());
        profileNumFriend.setText("Friends: " + pi.numFriends);
        profileNumPost.setText("Posts: " + pi.numPosts);

        ObservableList<Text> schools = FXCollections.observableArrayList();
        ObservableList<Text> univers = FXCollections.observableArrayList();
        ObservableList<Text> jobs = FXCollections.observableArrayList();
        for (Facility facility : pi.facilities){
            if (facility.type.equals("School"))schools.add(new Text(facility.name + ", " + facility.location.makeString()));
            if (facility.type.equals("University"))univers.add(new Text(facility.name + ", " + facility.location.makeString()));
            if (facility.type.equals("Work"))jobs.add(new Text(facility.name + ", " + facility.location.makeString()));
        }
        profileSchools.setItems(schools);
        profileUnivers.setItems(univers);
        profileJobs.setItems(jobs);

        ObservableList<PostsSceneController.PostPane> posts = FXCollections.observableArrayList();
        for (Post post : pi.posts){
            posts.add(new PostsSceneController.PostPane(post, Main.user.user_id));
        }
        profilePosts.setItems(posts);


        // TODO: 03.06.2020  
    }

    public void friendsButtonHandler(MouseEvent event) {
        Main.setFriendsScene(profileId);
    }
}
