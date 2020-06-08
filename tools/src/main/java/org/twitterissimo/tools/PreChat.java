package org.twitterissimo.tools;

import java.sql.Timestamp;

public class PreChat {
    public int me;
    public int other;
    public String text;
    public Timestamp timestamp;

    public PreChat(int me, int other, String text, Timestamp timestamp) {
        this.me = me;
        this.other = other;
        this.text = text;
        this.timestamp = timestamp;
    }
}
