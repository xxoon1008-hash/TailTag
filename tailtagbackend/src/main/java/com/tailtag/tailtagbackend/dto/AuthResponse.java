package com.tailtag.tailtagbackend.dto;

public class AuthResponse {

    private String token;
    private String email;
    private String nickname;

    public AuthResponse(String token, String email, String nickname) {
        this.token = token;
        this.email = email;
        this.nickname = nickname;
    }

    public String getToken() { return token; }
    public String getEmail() { return email; }
    public String getNickname() { return nickname; }
}
