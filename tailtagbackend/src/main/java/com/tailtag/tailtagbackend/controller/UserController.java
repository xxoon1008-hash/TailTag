package com.tailtag.tailtagbackend.controller;

import com.tailtag.tailtagbackend.dto.UpdateNicknameRequest;
import com.tailtag.tailtagbackend.dto.UpdatePasswordRequest;
import com.tailtag.tailtagbackend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PatchMapping("/me/nickname")
    public ResponseEntity<Map<String, String>> updateNickname(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody UpdateNicknameRequest request) {
        userService.updateNickname(email, request.getNickname());
        return ResponseEntity.ok(Map.of("nickname", request.getNickname()));
    }

    @PatchMapping("/me/password")
    public ResponseEntity<Map<String, String>> updatePassword(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody UpdatePasswordRequest request) {
        userService.updatePassword(email, request.getCurrentPassword(), request.getNewPassword());
        return ResponseEntity.ok(Map.of("message", "비밀번호가 변경되었습니다."));
    }
}
