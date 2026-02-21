package com.flashcard.backend.controller;

import com.flashcard.backend.service.StoreService;
import com.flashcard.backend.user.StoreItem;
import com.flashcard.backend.user.User;
import com.flashcard.backend.repository.UserRepository;
import com.flashcard.backend.service.UserDetailsImpl;
import com.flashcard.backend.security.jwt.JwtUtils;
import com.flashcard.backend.security.jwt.AuthEntryPointJwt;
import com.flashcard.backend.security.jwt.AuthTokenFilter;
import com.flashcard.backend.security.filter.AuthRateLimitFilter;
import com.flashcard.backend.service.UserDetailsServiceImpl;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.lang.NonNull;
import org.springframework.lang.Nullable;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.core.MethodParameter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.junit.jupiter.api.BeforeEach;

import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(StoreController.class)
class StoreControllerTest {
    
    // We'll use standalone setup to ensure @AuthenticationPrincipal is resolved correctly
    private MockMvc mockMvc;

    @MockBean
    private StoreService storeService;

    @MockBean
    private UserRepository userRepository;

    @MockBean
    private JwtUtils jwtUtils;

    @MockBean
    private UserDetailsServiceImpl userDetailsService;

    @MockBean
    private AuthEntryPointJwt unauthorizedHandler;

    @MockBean
    private AuthTokenFilter authTokenFilter;

    @MockBean
    private AuthRateLimitFilter authRateLimitFilter;

    @Autowired
    private StoreController storeController;

    private UserDetailsImpl testUserDetails;

    @BeforeEach
    void setup() {
        this.mockMvc = MockMvcBuilders.standaloneSetup(storeController)
                .setCustomArgumentResolvers(new HandlerMethodArgumentResolver() {
                    @Override
                    public boolean supportsParameter(@NonNull MethodParameter parameter) {
                        return parameter.getParameterType().isAssignableFrom(UserDetailsImpl.class);
                    }

                    @Override
                    public Object resolveArgument(@NonNull MethodParameter parameter, @Nullable ModelAndViewContainer mavContainer,
                                                  @NonNull NativeWebRequest webRequest, @Nullable WebDataBinderFactory binderFactory) {
                        return testUserDetails;
                    }
                })
                .build();
    }
    @Test
    void getAllItems_ReturnsList() throws Exception {
        StoreItem item = new StoreItem();
        item.setCode("AURA_BLUE");
        when(storeService.getAllItems()).thenReturn(Collections.singletonList(item));

        mockMvc.perform(get("/api/store/items"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].code").value("AURA_BLUE"));
    }

    @Test
    void purchaseItem_Success() throws Exception {
        User user = new User();
        user.setId(1L);
        user.setUsername("testuser");
        user.setEmail("test@example.com");
        user.setRoles(Collections.emptySet()); // Ensure initialized
        
        this.testUserDetails = UserDetailsImpl.build(user);
        
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        doNothing().when(storeService).purchaseItem(any(), anyString());

        mockMvc.perform(post("/api/store/purchase/AURA_BLUE"))
                .andExpect(status().isOk())
                .andExpect(content().string("Purchase successful"));
    }

    @Test
    void purchaseItem_Failure_ReturnsBadRequest() throws Exception {
        User user = new User();
        user.setId(1L);
        user.setUsername("testuser");
        user.setEmail("test@example.com");
        user.setRoles(Collections.emptySet());
        
        this.testUserDetails = UserDetailsImpl.build(user);
        
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        doThrow(new RuntimeException("Insufficient coins")).when(storeService).purchaseItem(any(), anyString());

        mockMvc.perform(post("/api/store/purchase/AURA_BLUE"))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Insufficient coins"));
    }
}
