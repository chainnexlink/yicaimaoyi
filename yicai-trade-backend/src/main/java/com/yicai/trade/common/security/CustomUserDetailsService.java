package com.yicai.trade.common.security;

import com.yicai.trade.module.auth.entity.User;
import com.yicai.trade.module.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {
    
    private final UserRepository userRepository;
    
    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // 先按用户名、邮箱、手机号查找
        Optional<User> opt = userRepository.findByUsername(username);
        if (opt.isEmpty()) opt = userRepository.findByEmail(username);
        if (opt.isEmpty()) opt = userRepository.findByPhone(username);
        // JWT token中存的是用户ID，按ID查找
        if (opt.isEmpty()) {
            try {
                long id = Long.parseLong(username);
                opt = userRepository.findById(id);
            } catch (NumberFormatException ignored) {}
        }

        User user = opt.orElseThrow(() -> new UsernameNotFoundException("用户不存在: " + username));
        
        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(role -> new SimpleGrantedAuthority(role.getRoleCode()))
                .collect(Collectors.toList());
        
        return new org.springframework.security.core.userdetails.User(
                user.getId().toString(),
                user.getPassword(),
                user.getStatus().equals("ACTIVE"),
                true,
                true,
                true,
                authorities
        );
    }
}
