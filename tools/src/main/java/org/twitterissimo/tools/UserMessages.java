package org.twitterissimo.tools;

import java.io.Serializable;
import java.util.ArrayList;

public class UserMessages implements Serializable {
    public int myId;
    public int otherId;
    public ServerUser me;
    public ServerUser other;
    public ArrayList<Message> messages;
    public String reason;
    public UserMessages(){}
    public UserMessages(int myId_, int otherId_) {
        myId = myId_;
        otherId = otherId_;
    }
}
