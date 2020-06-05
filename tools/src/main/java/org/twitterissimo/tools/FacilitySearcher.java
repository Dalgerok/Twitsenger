package org.twitterissimo.tools;

import java.io.Serializable;

public class FacilitySearcher implements Serializable {
    public String facility_type;
    public String facility_name;
    public FacilitySearcher(String facility_type, String facility_name) {
        this.facility_type = facility_type;
        this.facility_name = facility_name;
    }

}
