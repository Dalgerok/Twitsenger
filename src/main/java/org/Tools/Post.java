package main.java.org.Tools;

import java.io.Serializable;
import java.sql.Time;
import java.sql.Timestamp;

public class Post implements Serializable {
    public int user_id;
    public String post_text;
    public Timestamp post_time;
    public int reposted_from;
    public int post_id;
    public String first_name;
    public String last_name;
    public String user_picture_url;
    public Post(int user_id, String post_text, Timestamp post_time, int reposted_from, int post_id, String first_name, String last_name, String user_picture_url) {
        this.user_id = user_id;
        this.post_text = post_text;
        this.post_time = post_time;
        this.reposted_from = reposted_from;
        this.post_id = post_id;
        this.first_name = first_name;
        this.last_name = last_name;
        this.user_picture_url = user_picture_url;
    }

    public Post(String s) {
        this.post_text = s;
    }

    public Post() {

    }
}
