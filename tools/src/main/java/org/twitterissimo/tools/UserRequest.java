package org.twitterissimo.tools;

import java.io.Serializable;
import java.util.Date;

public class UserRequest implements Serializable {
    public ProfileInfo from_whom;
    public Date request_date;
    public UserRequest(ProfileInfo from_whom, Date request_date) {
        this.from_whom = from_whom;
        this.request_date = request_date;
    }

    public UserRequest() {
    }
}
