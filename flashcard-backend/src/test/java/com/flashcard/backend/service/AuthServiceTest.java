package com.flashcard.backend.service;

import com.flashcard.backend.payload.request.SignupRequest;
import com.flashcard.backend.repository.RoleRepository;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.user.Role;
import com.flashcard.backend.user.User;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.lang.reflect.Proxy;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

class AuthServiceTest {

    @Test
    void registerUser_ignoresRequestedRoles_andAssignsRoleUser() {
        AtomicReference<User> savedUser = new AtomicReference<>();

        UserRepository userRepository = (UserRepository) Proxy.newProxyInstance(
                getClass().getClassLoader(),
                new Class[] { UserRepository.class },
                (proxy, method, args) -> {
                    return switch (method.getName()) {
                        case "existsByUsername" -> args[0].equals("Alice") ? false : false;
                        case "existsByEmail" -> args[0].equals("alice@example.com") ? false : false;
                        case "save" -> {
                            savedUser.set((User) args[0]);
                            yield args[0];
                        }
                        case "toString" -> "UserRepositoryProxy";
                        case "hashCode" -> System.identityHashCode(proxy);
                        case "equals" -> proxy == args[0];
                        default -> throw new UnsupportedOperationException(method.getName());
                    };
                });

        Role roleUser = new Role(1, "ROLE_USER");
        AtomicReference<String> roleLookupName = new AtomicReference<>();
        RoleRepository roleRepository = (RoleRepository) Proxy.newProxyInstance(
                getClass().getClassLoader(),
                new Class[] { RoleRepository.class },
                (proxy, method, args) -> {
                    return switch (method.getName()) {
                        case "findByName" -> {
                            roleLookupName.set((String) args[0]);
                            yield Optional.of(roleUser);
                        }
                        case "toString" -> "RoleRepositoryProxy";
                        case "hashCode" -> System.identityHashCode(proxy);
                        case "equals" -> proxy == args[0];
                        default -> throw new UnsupportedOperationException(method.getName());
                    };
                });

        PasswordEncoder encoder = new PasswordEncoder() {
            @Override
            public String encode(CharSequence rawPassword) {
                return "hashed";
            }

            @Override
            public boolean matches(CharSequence rawPassword, String encodedPassword) {
                return false;
            }
        };

        AuthService authService = new AuthService();
        authService.userRepository = userRepository;
        authService.roleRepository = roleRepository;
        authService.encoder = encoder;

        SignupRequest req = new SignupRequest();
        req.setUsername("  Alice  ");
        req.setEmail("  Alice@Example.com ");
        req.setPassword("password123");
        req.setRole(Set.of("admin"));

        authService.registerUser(req);

        User saved = savedUser.get();
        assertThat(saved.getUsername()).isEqualTo("Alice");
        assertThat(saved.getEmail()).isEqualTo("alice@example.com");
        assertThat(saved.getPassword()).isEqualTo("hashed");
        assertThat(saved.getRoles()).extracting(Role::getName).containsExactly("ROLE_USER");
        assertThat(roleLookupName.get()).isEqualTo("ROLE_USER");
    }

    @Test
    void registerUser_whenDuplicate_returnsBadRequestWithoutSaving() {
        AtomicReference<User> savedUser = new AtomicReference<>();

        UserRepository userRepository = (UserRepository) Proxy.newProxyInstance(
                getClass().getClassLoader(),
                new Class[] { UserRepository.class },
                (proxy, method, args) -> {
                    return switch (method.getName()) {
                        case "existsByUsername" -> true;
                        case "save" -> {
                            savedUser.set((User) args[0]);
                            yield args[0];
                        }
                        case "toString" -> "UserRepositoryProxy";
                        case "hashCode" -> System.identityHashCode(proxy);
                        case "equals" -> proxy == args[0];
                        default -> throw new UnsupportedOperationException(method.getName());
                    };
                });

        AuthService authService = new AuthService();
        authService.userRepository = userRepository;

        SignupRequest req = new SignupRequest();
        req.setUsername("Alice");
        req.setEmail("alice@example.com");
        req.setPassword("password123");

        var resp = authService.registerUser(req);

        assertThat(resp.getStatusCode().value()).isEqualTo(400);
        assertThat(savedUser.get()).isNull();
    }
}
