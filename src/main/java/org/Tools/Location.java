package main.java.org.Tools;

import java.io.Serializable;

public class Location implements Serializable {
    public String country;
    public String city;
    public int location_id;

    public Location(String country, String city, int location_id) {
        this.country = country;
        this.city = city;
        this.location_id = location_id;
    }

    public String makeString() {
        return country + "," + city;
    }
}
