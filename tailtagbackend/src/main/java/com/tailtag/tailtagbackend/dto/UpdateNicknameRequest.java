package com.tailtag.tailtagbackend.dto;

import jakarta.validation.constraints.NotBlank;

public class UpdateNicknameRequest {

    @NotBlank(message = "닉네임은 필수입니다.")
    private String nickname;

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
}
