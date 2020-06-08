package org.twitterissimo.tools;

import java.io.Serializable;

public class ChatItem implements Serializable {
    public ServerUser me;
    public ServerUser other;
    public Message message;
    public ChatItem(ServerUser me, ServerUser other, Message message) {
        this.me = me;
        this.other = other;
        this.message = message;
    }

    public ChatItem(ServerUser me) {
        this.me = me;
    }

    public ChatItem() {
    }
}
