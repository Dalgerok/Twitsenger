package org.twitterissimo.tools;

import java.io.Serializable;
import java.util.Date;

public class UserRequest implements Serializable {
    public ProfileInfo from_whom;
    public UserRequest(ProfileInfo from_whom) {
        this.from_whom = from_whom;
    }

    public UserRequest() {
    }
}
