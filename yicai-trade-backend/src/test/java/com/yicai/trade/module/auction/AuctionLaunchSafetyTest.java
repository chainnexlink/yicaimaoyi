package com.yicai.trade.module.auction;

import com.yicai.trade.module.auction.dto.AuctionCreateRequest;
import com.yicai.trade.module.auction.dto.AuctionResponse;
import com.yicai.trade.module.auction.dto.BidRequest;
import com.yicai.trade.module.auction.entity.Auction;
import com.yicai.trade.module.auction.entity.AuctionBid;
import com.yicai.trade.module.auction.repository.*;
import com.yicai.trade.module.auction.service.impl.AuctionServiceImpl;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import com.yicai.trade.module.contract.service.ContractService;
import com.yicai.trade.module.message.service.MessageService;
import com.yicai.trade.module.order.service.OrderService;
import com.yicai.trade.module.smartmatch.service.SmartMatchService;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuctionLaunchSafetyTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Mock private AuctionRepository auctionRepository;
    @Mock private AuctionBidRepository bidRepository;
    @Mock private AuctionSignupRepository signupRepository;
    @Mock private AuctionInvitationRepository invitationRepository;
    @Mock private AuctionSupplierListRepository supplierListRepository;
    @Mock private AuctionOperationLogRepository operationLogRepository;
    @Mock private AuctionSupplierScoreRepository scoreRepository;
    @Mock private BuyerRepository buyerRepository;
    @Mock private SupplierRepository supplierRepository;
    @Mock private OrderService orderService;
    @Mock private MessageService messageService;
    @Mock private ContractService contractService;
    @Mock private SimpMessagingTemplate messagingTemplate;
    @Mock private SmartMatchService smartMatchService;
    @Mock private AuctionDepositRepository auctionDepositRepository;

    @InjectMocks private AuctionServiceImpl auctionService;

    @Test
    void rejectsIncompleteCreateAndNonPositiveBidRequests() {
        AuctionCreateRequest createRequest = AuctionCreateRequest.builder()
                .productName(" ")
                .quantity(0)
                .startingPrice(BigDecimal.ZERO)
                .build();
        BidRequest bidRequest = BidRequest.builder()
                .auctionId(42L)
                .bidPrice(new BigDecimal("-0.01"))
                .build();

        assertThat(validator.validate(createRequest))
                .extracting(violation -> violation.getPropertyPath().toString())
                .contains("productName", "specification", "quantity", "startingPrice", "startTime", "endTime");
        assertThat(validator.validate(bidRequest))
                .extracting(violation -> violation.getPropertyPath().toString())
                .contains("bidPrice");
    }

    @Test
    void publicAuctionDetailMasksSupplierAndInternalFields() {
        LocalDateTime now = LocalDateTime.now();
        Auction auction = Auction.builder()
                .id(42L)
                .auctionNo("AUC-42")
                .buyerId(9001L)
                .buyerCompany("YiCai Global")
                .productName("Test product")
                .specification("Comparable specification")
                .quantity(100)
                .unit("pcs")
                .currency("USD")
                .startingPrice(new BigDecimal("10.00"))
                .currentLowestPrice(new BigDecimal("9.20"))
                .minDecrement(new BigDecimal("0.10"))
                .startTime(now.minusHours(1))
                .endTime(now.plusHours(1))
                .status("ACTIVE")
                .approverId(88L)
                .approvalRemark("internal note")
                .winnerSupplierId(77L)
                .winnerCompany("Secret Factory Ltd")
                .orderId(100L)
                .contractId(101L)
                .build();
        AuctionBid bid = AuctionBid.builder()
                .id(5L)
                .auction(auction)
                .supplierId(77L)
                .supplierCompany("Secret Factory Ltd")
                .bidPrice(new BigDecimal("9.20"))
                .bidSequence(3)
                .isLowest(true)
                .isWinner(true)
                .createdAt(now)
                .build();
        when(auctionRepository.findById(42L)).thenReturn(Optional.of(auction));
        when(bidRepository.findByAuctionIdOrderByCreatedAtDesc(42L)).thenReturn(List.of(bid));

        AuctionResponse response = auctionService.getAuctionDetailWithBids(42L);

        assertThat(response.getBuyerId()).isNull();
        assertThat(response.getApproverId()).isNull();
        assertThat(response.getApprovalRemark()).isNull();
        assertThat(response.getWinnerSupplierId()).isNull();
        assertThat(response.getWinnerCompany()).isNull();
        assertThat(response.getOrderId()).isNull();
        assertThat(response.getContractId()).isNull();
        assertThat(response.getSignups()).isNull();
        assertThat(response.getInvitations()).isNull();
        assertThat(response.getOperationLogs()).isNull();
        assertThat(response.getBids()).singleElement().satisfies(publicBid -> {
            assertThat(publicBid.getId()).isNull();
            assertThat(publicBid.getSupplierId()).isNull();
            assertThat(publicBid.getSupplierCompany()).isEqualTo("匿名供应商 A");
            assertThat(publicBid.getIsWinner()).isFalse();
        });
        verifyNoInteractions(signupRepository, invitationRepository, operationLogRepository, scoreRepository);
    }
}
