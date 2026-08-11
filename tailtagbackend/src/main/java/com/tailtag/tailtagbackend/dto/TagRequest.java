package com.tailtag.tailtagbackend.dto;

import jakarta.validation.constraints.NotBlank;

public class TagRequest {

    @NotBlank(message = "태그 이름은 필수입니다.")
    private String name;

    @NotBlank(message = "기기 ID는 필수입니다.")
    private String deviceId;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }
}
