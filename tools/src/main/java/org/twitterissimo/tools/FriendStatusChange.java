package org.twitterissimo.tools;


import java.io.Serializable;

public class FriendStatusChange implements Serializable {
    public enum FriendQuery{
        ADD, REMOVE, REMOVE_REQUEST
    }
    public ServerUser from;
    public ServerUser to;
    public FriendQuery query;
    public FriendStatusChange(ServerUser from, ServerUser to, FriendQuery query){
        this.from = from;
        this.to = to;
        this.query = query;
    }
}
