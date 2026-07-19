package com.yicai.trade.module.order.repository;

import com.yicai.trade.module.order.entity.OrderFile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderFileRepository extends JpaRepository<OrderFile, Long> {

    List<OrderFile> findByOrderId(Long orderId);

    List<OrderFile> findByOrderIdAndFileType(Long orderId, String fileType);
}
