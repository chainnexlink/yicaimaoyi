package com.yicai.trade.module.membership.repository;

import com.yicai.trade.module.membership.entity.Membership;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MembershipRepository extends JpaRepository<Membership, Long> {
    Optional<Membership> findByUserId(Long userId);
    Page<Membership> findByLevel(String level, Pageable pageable);
    long countByLevel(String level);
}
