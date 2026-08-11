package com.tailtag.tailtagbackend.controller;

import com.tailtag.tailtagbackend.dto.TagRequest;
import com.tailtag.tailtagbackend.dto.TagResponse;
import com.tailtag.tailtagbackend.service.TagService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tags")
public class TagController {

    private final TagService tagService;

    public TagController(TagService tagService) {
        this.tagService = tagService;
    }

    @GetMapping
    public ResponseEntity<List<TagResponse>> getTags(@AuthenticationPrincipal String email) {
        return ResponseEntity.ok(tagService.getTagsForUser(email));
    }

    @PostMapping
    public ResponseEntity<TagResponse> addTag(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody TagRequest request) {
        return ResponseEntity.ok(tagService.addTag(email, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTag(
            @AuthenticationPrincipal String email,
            @PathVariable Long id) {
        tagService.deleteTag(email, id);
        return ResponseEntity.noContent().build();
    }
}
