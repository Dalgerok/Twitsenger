package org.twitterissimo.tools;

import java.io.Serializable;

public class GetUserFriendRequests implements Serializable {
    public final int id;
    public GetUserFriendRequests(int id) {
        this.id = id;
    }
}
