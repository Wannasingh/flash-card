package com.flashcard.backend.repository;

import com.flashcard.backend.user.UserIdentity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserIdentityRepository extends JpaRepository<UserIdentity, Long> {
    Optional<UserIdentity> findByProviderAndProviderUserId(String provider, String providerUserId);
}
