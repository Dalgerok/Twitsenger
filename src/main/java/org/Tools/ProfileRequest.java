package main.java.org.Tools;

import java.io.Serializable;

public class ProfileRequest implements Serializable {
    private final int id;

    public ProfileRequest(int id) {
        this.id = id;
    }

    public int getId() {
        return id;
    }
}
