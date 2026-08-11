package com.tailtag.tailtagbackend.service;

import com.tailtag.tailtagbackend.entity.User;
import com.tailtag.tailtagbackend.exception.InvalidCredentialsException;
import com.tailtag.tailtagbackend.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public User getByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("사용자를 찾을 수 없습니다."));
    }

    public void updateNickname(String email, String nickname) {
        User user = getByEmail(email);
        user.setNickname(nickname);
        userRepository.save(user);
    }

    public void updatePassword(String email, String currentPassword, String newPassword) {
        User user = getByEmail(email);
        if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
            throw new InvalidCredentialsException("현재 비밀번호가 올바르지 않습니다.");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }
}
