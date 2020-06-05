package org.twitterissimo.tools;

import java.io.Serializable;
import java.sql.Date;
import java.util.ArrayList;

public class ProfileInfo extends ServerUser implements Serializable {
    public Location location;
    public ArrayList<Post> posts;
    public ArrayList<Facility> facilities;
    public int numFriends;
    public int numPosts;
    public ProfileInfo(String first_name, String last_name, Date birthday, String email, String relationship_status, String gender,
                       String user_password, int user_location_id, String picture_url, int user_id) {
        super(first_name, last_name, birthday, email, relationship_status, gender, user_password, user_location_id, picture_url, user_id);
    }
}
