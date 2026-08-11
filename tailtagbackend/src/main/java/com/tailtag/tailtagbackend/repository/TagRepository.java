package com.tailtag.tailtagbackend.repository;

import com.tailtag.tailtagbackend.entity.Tag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TagRepository extends JpaRepository<Tag, Long> {
    List<Tag> findByUserEmail(String email);
    Optional<Tag> findByIdAndUserEmail(Long id, String email);
    boolean existsByUserEmailAndDeviceId(String email, String deviceId);
}
