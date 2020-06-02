package main.java.org.Tools;

import java.io.Serializable;
import java.time.LocalDate;

public class RegisterInfo implements Serializable {
    private final String firstName;
    private final String lastName;
    private final LocalDate birthday;
    private final String email;
    private final String relationship;
    private final String gender;
    private final String password;

    public RegisterInfo(String firstName, String lastName, LocalDate birthday, String email, String relationship, String gender, String password) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.birthday = birthday;

        this.email = email;
        this.relationship = relationship;
        this.gender = gender;
        this.password = password;
    }

    public String getFirstName() {
        return "'" + firstName + "'";
    }

    public String getLastName() {
        return "'" + lastName + "'";
    }

    public String getBirthday() {
        return "'" + birthday.toString() + "'";
    }

    public String getEmail() {
        return "'" + email + "'";
    }

    public String getRelationship() {
        return "'" + relationship + "'";
    }

    public String getGender() {
        return "'" + gender + "'";
    }

    public String getPassword() {
        return "'" + password + "'";
    }
}
