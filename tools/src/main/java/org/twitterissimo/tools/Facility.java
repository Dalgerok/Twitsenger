package org.twitterissimo.tools;

import java.io.Serializable;

public class Facility implements Serializable {
    public String name;
    public Location location;
    public String type;
    public int facility_id;

    public Facility(String name, Location location, String type, int facility_id) {
        this.name = name;
        this.location = location;
        this.type = type;
        this.facility_id = facility_id;
    }
}
