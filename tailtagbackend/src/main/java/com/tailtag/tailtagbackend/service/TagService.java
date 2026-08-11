package com.tailtag.tailtagbackend.service;

import com.tailtag.tailtagbackend.dto.TagRequest;
import com.tailtag.tailtagbackend.dto.TagResponse;
import com.tailtag.tailtagbackend.entity.Tag;
import com.tailtag.tailtagbackend.entity.User;
import com.tailtag.tailtagbackend.repository.TagRepository;
import com.tailtag.tailtagbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class TagService {

    private final TagRepository tagRepository;
    private final UserRepository userRepository;

    public TagService(TagRepository tagRepository, UserRepository userRepository) {
        this.tagRepository = tagRepository;
        this.userRepository = userRepository;
    }

    public List<TagResponse> getTagsForUser(String email) {
        return tagRepository.findByUserEmail(email).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public TagResponse addTag(String email, TagRequest request) {
        if (tagRepository.existsByUserEmailAndDeviceId(email, request.getDeviceId())) {
            throw new RuntimeException("이미 등록된 태그입니다.");
        }
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        Tag tag = new Tag(user, request.getName(), request.getDeviceId());
        return toResponse(tagRepository.save(tag));
    }

    public void deleteTag(String email, Long id) {
        Tag tag = tagRepository.findByIdAndUserEmail(id, email)
                .orElseThrow(() -> new RuntimeException("태그를 찾을 수 없습니다."));
        tagRepository.delete(tag);
    }

    private TagResponse toResponse(Tag tag) {
        return new TagResponse(tag.getId(), tag.getName(), tag.getDeviceId(), tag.getRegisteredAt());
    }
}
