package main.java.org.Tools;

import java.io.Serializable;

public class LoginInfo implements Serializable {
    private final String email;
    private final String password;

    public LoginInfo(String email, String password) {
        this.email = email;
        this.password = password;
    }

    public String getEmail() {
        return "'" + email + "'";
    }

    public String getPassword() {
        return "'" + password + "'";
    }
}
