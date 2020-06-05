package org.twitterissimo.tools;

import java.io.Serializable;
import java.util.Date;

public class UserFacility implements Serializable {
    public int userId;
    public Facility facility;
    public int facilityId;
    public Date date_from;
    public Date date_to;
    public String description;
    public boolean add;
    public UserFacility(int userId, int facilityId, Date date_from, Date date_to, String description) {
        this.userId = userId;
        this.facilityId = facilityId;
        this.date_from = date_from;
        this.date_to = date_to;
        this.description = description;
    }

    public UserFacility(int userId, int facilityId, Date date_from) {
        this.userId = userId;
        this.facilityId = facilityId;
        this.date_from = date_from;
    }

    public void setFacility(Facility facility){
        this.facility = facility;
    }

    public void setAdd(boolean add) {
        this.add = add;
    }
}
