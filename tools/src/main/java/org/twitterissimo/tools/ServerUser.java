package org.twitterissimo.tools;

import java.io.Serializable;
import java.sql.Date;

public class ServerUser implements Serializable {
    public String first_name;
    public String last_name;
    public Date birthday;
    public String email;
    public String relationship_status;
    public String gender;
    public String user_password;
    public int user_location_id;
    public String picture_url;
    public int user_id;
    public ServerUser(String first_name, String last_name, Date birthday, String email, String relationship_status,
                      String gender, String user_password, int user_location_id, String picture_url, int user_id) {
        this.first_name = first_name;
        this.last_name = last_name;
        this.birthday = birthday;
        this.email = email;
        this.relationship_status = relationship_status;
        this.gender = gender;
        this.user_password = user_password;
        this.user_location_id = user_location_id;
        this.picture_url = picture_url;
        this.user_id = user_id;
    }

    public ServerUser() {

    }
}
