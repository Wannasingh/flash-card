package com.flashcard.backend.security.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import jakarta.servlet.FilterChain;

import static org.assertj.core.api.Assertions.assertThat;

class AuthRateLimitFilterTest {

    @Test
    void signin_rateLimitsAfterDefaultThreshold() throws Exception {
        AuthRateLimitFilter filter = new AuthRateLimitFilter(new ObjectMapper());

        CountingChain chain = new CountingChain();

        for (int i = 0; i < 10; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest();
            req.setMethod("POST");
            req.setRequestURI("/api/auth/signin");
            req.setRemoteAddr("1.2.3.4");

            MockHttpServletResponse resp = new MockHttpServletResponse();
            filter.doFilter(req, resp, chain);
            assertThat(resp.getStatus()).isIn(200, 0);
        }

        MockHttpServletRequest req = new MockHttpServletRequest();
        req.setMethod("POST");
        req.setRequestURI("/api/auth/signin");
        req.setRemoteAddr("1.2.3.4");

        MockHttpServletResponse resp = new MockHttpServletResponse();
        filter.doFilter(req, resp, chain);

        assertThat(resp.getStatus()).isEqualTo(429);
        assertThat(resp.getContentType()).isEqualTo("application/json");
        assertThat(chain.count).isEqualTo(10);
    }

    private static class CountingChain implements FilterChain {
        int count = 0;

        @Override
        public void doFilter(jakarta.servlet.ServletRequest request, jakarta.servlet.ServletResponse response) {
            count++;
        }
    }
}
