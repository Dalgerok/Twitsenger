package org.twitterissimo.tools;

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
        if ((country == null || country.length() == 0) && (city == null || city.length() == 0))
            return "";
        if (country == null || country.length() == 0)
            return city;
        if (city == null || city.length() == 0)
            return country;
        return country + ", " + city;
    }
}
