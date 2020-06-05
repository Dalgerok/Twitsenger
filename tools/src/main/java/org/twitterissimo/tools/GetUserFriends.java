package org.twitterissimo.tools;

import java.io.Serializable;

public class GetUserFriends implements Serializable {
    public final int id;
    public GetUserFriends(int id) {
        this.id = id;
    }
}
