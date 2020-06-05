package org.twitterissimo.tools;

import java.io.Serializable;

public class SearchProfileFilter implements Serializable {
    public String firstName;
    public String lastName;
    public String country;
    public String city;

    public SearchProfileFilter(String firstName, String lastName, String country, String city) {
        if (firstName == null)firstName = "";
        if (lastName == null)lastName = "";
        if (country == null)country = "";
        if (city == null)city = "";
        this.firstName = firstName;
        this.lastName = lastName;
        this.country = country;
        this.city = city;
    }

    // TODO: 04.06.2020
}
