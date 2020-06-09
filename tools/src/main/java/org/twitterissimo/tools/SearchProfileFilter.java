package org.twitterissimo.tools;

import java.io.Serializable;
import java.util.Date;

public class SearchProfileFilter implements Serializable {
    public String firstName;
    public String lastName;
    public String country;
    public String city;
    public Integer facilityId;
    public Date dateFrom;
    public Date dateTo;

    public SearchProfileFilter(String firstName, String lastName, String country, String city, Integer facilityId, Date dateFrom, Date dateTo) {
        if (firstName == null)firstName = "";
        if (lastName == null)lastName = "";
        if (country == null)country = "";
        if (city == null)city = "";
        if (facilityId == null)facilityId = 0;
        this.firstName = firstName;
        this.lastName = lastName;
        this.country = country;
        this.city = city;
        this.facilityId = facilityId;
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
    }

    // TODO: 04.06.2020
}
