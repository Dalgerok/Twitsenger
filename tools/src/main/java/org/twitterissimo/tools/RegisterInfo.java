package org.twitterissimo.tools;

import java.io.Serializable;
import java.time.LocalDate;

public class RegisterInfo implements Serializable {
    private final String firstName;
    private final String lastName;
    private final LocalDate birthday;
    private final String email;
    private final String relationship;
    private final String gender;
    private final String pictureURL;
    private final String password;
    private final boolean update;

    public RegisterInfo(String firstName, String lastName, LocalDate birthday, String email, String relationship, String gender, String pictureURL, String password, boolean update) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.birthday = birthday;

        this.email = email;
        this.relationship = relationship;
        this.gender = gender;
        this.pictureURL = pictureURL;
        this.password = password;
        this.update = update;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public String getBirthday() {
        return birthday.toString();
    }

    public String getEmail() {
        return email;
    }

    public String getRelationship() {
        return relationship;
    }

    public String getGender() {
        return gender;
    }

    public String getPictureURL() {
        return pictureURL;
    }

    public String getPassword() {
        return password;
    }

    public boolean getUpdate() {
        return update;
    }

}
