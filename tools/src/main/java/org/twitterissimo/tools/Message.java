package org.twitterissimo.tools;

import java.io.Serializable;
import java.sql.Timestamp;

public class Message implements Serializable {
    public ServerUser from;
    public ServerUser to;
    public String text;
    public Timestamp timestamp;

    public Message(ServerUser from, ServerUser to, String text, Timestamp timestamp) {
        this.from = from;
        this.to = to;
        this.text = text;
        this.timestamp = timestamp;
    }
}
