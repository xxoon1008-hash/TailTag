package com.tailtag.tailtagbackend.dto;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class TagResponse {

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    private Long id;
    private String name;
    private String deviceId;
    private String registeredAt;

    public TagResponse(Long id, String name, String deviceId, LocalDateTime registeredAt) {
        this.id = id;
        this.name = name;
        this.deviceId = deviceId;
        this.registeredAt = registeredAt != null ? registeredAt.format(FORMATTER) : null;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getDeviceId() { return deviceId; }
    public String getRegisteredAt() { return registeredAt; }
}
