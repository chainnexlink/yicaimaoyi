package com.yicai.trade.module.membership.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.membership.dto.MembershipResponse;
import com.yicai.trade.module.membership.entity.Membership;
import com.yicai.trade.module.membership.repository.MembershipRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MembershipServiceImpl implements MembershipService {

    private final MembershipRepository membershipRepository;

    @Override
    public MembershipResponse getByUserId(Long userId) {
        return membershipRepository.findByUserId(userId).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("Membership not found for user: " + userId));
    }

    @Override
    public PageResult<MembershipResponse> list(String level, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "totalPoints"));
        Page<Membership> p = (level != null && !level.isEmpty())
                ? membershipRepository.findByLevel(level, pageable)
                : membershipRepository.findAll(pageable);
        List<MembershipResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void updateLevel(Long id, String level) {
        Membership m = membershipRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Membership not found: " + id));
        m.setLevel(level);
        membershipRepository.save(m);
    }

    @Override
    @Transactional
    public void addPoints(Long id, int points) {
        Membership m = membershipRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Membership not found: " + id));
        m.setPoints((m.getPoints() != null ? m.getPoints() : 0) + points);
        m.setTotalPoints((m.getTotalPoints() != null ? m.getTotalPoints() : 0) + points);
        // Auto upgrade level
        if (m.getTotalPoints() >= 5000) m.setLevel("DIAMOND");
        else if (m.getTotalPoints() >= 1000) m.setLevel("VIP");
        membershipRepository.save(m);
    }

    @Override
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", membershipRepository.count());
        stats.put("normal", membershipRepository.countByLevel("NORMAL"));
        stats.put("vip", membershipRepository.countByLevel("VIP"));
        stats.put("diamond", membershipRepository.countByLevel("DIAMOND"));
        return stats;
    }

    private MembershipResponse toResponse(Membership m) {
        MembershipResponse r = new MembershipResponse();
        r.setId(m.getId());
        r.setUserId(m.getUserId());
        r.setUserName(m.getUserName());
        r.setCompanyName(m.getCompanyName());
        r.setLevel(m.getLevel());
        r.setPoints(m.getPoints());
        r.setTotalPoints(m.getTotalPoints());
        r.setExpireAt(m.getExpireAt());
        r.setCreatedAt(m.getCreatedAt());
        return r;
    }
}
