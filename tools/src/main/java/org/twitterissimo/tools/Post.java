package org.twitterissimo.tools;

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
    public Post repost;
    public int number_of_likes;
    public Post(int post_id){
        this.post_id = post_id;
    }
    public Post(int user_id, String post_text, Timestamp post_time, int reposted_from, int post_id,
                String first_name, String last_name, String user_picture_url, int number_of_likes) {
        this.user_id = user_id;
        this.post_text = post_text;
        this.post_time = post_time;
        this.reposted_from = reposted_from;
        this.post_id = post_id;
        this.first_name = first_name;
        this.last_name = last_name;
        this.user_picture_url = user_picture_url;
        this.number_of_likes = number_of_likes;
    }

    public Post(String s) {
        this.post_text = s;
    }
    public Post(String s, int reposted_from){
        this.post_text = s;
        this.reposted_from = reposted_from;
    }

    public Post() {

    }

    public Post(Integer user_id, String post_text, Timestamp post_time, int reposted_from, int post_id,
                String first_name, String last_name, String user_picture_url, Post repost, int number_of_likes) {
        this.user_id = user_id;
        this.post_text = post_text;
        this.post_time = post_time;
        this.reposted_from = reposted_from;
        this.post_id = post_id;
        this.first_name = first_name;
        this.last_name = last_name;
        this.user_picture_url = user_picture_url;
        this.repost = repost;
        this.number_of_likes = number_of_likes;
    }
}
