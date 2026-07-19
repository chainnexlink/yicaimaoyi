-- =====================================================
-- 易采贸易平台 H2 测试数据初始化脚本
-- 所有表名/列名严格对齐 JPA Entity 定义
-- 审计字段(created_at/updated_at)由JPA自动管理，不在SQL中指定
-- =====================================================

-- ==================== 1. 用户 ====================
INSERT INTO t_user (username, password, email, phone, real_name, user_type, status) VALUES
('admin',     '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'admin@yicai.com',     '13800138000', '系统管理员', 'ADMIN',    'ACTIVE'),
('buyer1',    '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'buyer1@test.com',     '13800138001', '张采购',   'BUYER',    'ACTIVE'),
('buyer2',    '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'buyer2@test.com',     '13800138002', '李采购',   'BUYER',    'ACTIVE'),
('buyer3',    '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'buyer3@test.com',     '13800138003', '王采购',   'BUYER',    'ACTIVE'),
('supplier1', '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'supplier1@test.com',  '13900139001', '陈供应',   'SUPPLIER', 'ACTIVE'),
('supplier2', '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'supplier2@test.com',  '13900139002', '刘供应',   'SUPPLIER', 'ACTIVE'),
('supplier3', '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'supplier3@test.com',  '13900139003', '周供应',   'SUPPLIER', 'ACTIVE');

-- ==================== 2. 用户角色 ====================
INSERT INTO t_user_role (user_id, role_code) VALUES
(1, 'ROLE_ADMIN'),
(2, 'ROLE_BUYER'),
(3, 'ROLE_BUYER'),
(4, 'ROLE_BUYER'),
(5, 'ROLE_SUPPLIER'),
(6, 'ROLE_SUPPLIER'),
(7, 'ROLE_SUPPLIER');

-- ==================== 3. 采购商 ====================
INSERT INTO t_buyer (user_id, company_name, contact_person, contact_phone, address, industry, description) VALUES
(2, '深圳科技有限公司', '张经理', '13800138001', '深圳市南山区科技园',   '电子科技',   '电子产品研发销售'),
(3, '广州贸易集团',     '李总监', '13800138002', '广州市天河区CBD',     '进出口贸易', '国际贸易代理'),
(4, '上海进出口公司',   '王采购', '13800138003', '上海市浦东新区',      '外贸服务',   '外贸综合服务');

-- ==================== 4. 供应商 ====================
INSERT INTO t_supplier (user_id, company_name, contact_person, contact_phone, business_license, address, description, status) VALUES
(5, '东莞精密制造厂', '陈供应', '13900139001', 'SL20260001', '东莞市长安镇工业区',   '精密五金加工制造',     'APPROVED'),
(6, '佛山五金加工厂', '刘供应', '13900139002', 'SL20260002', '佛山市顺德区工业园',   '金属制品加工',         'APPROVED'),
(7, '深圳电子科技',   '周供应', '13900139003', 'SL20260003', '深圳市宝安区电子城',   '电子元器件生产销售',   'PENDING');

-- ==================== 5. 询价 ====================
INSERT INTO t_inquiry (buyer_id, title, description, product_category, expected_quantity, unit, status, deadline) VALUES
(1, '不锈钢保温杯采购', '304不锈钢材质，500ml容量，需要定制Logo',         '五金配件',   5000,  '件', 'OPEN',   DATEADD('DAY', 30, NOW())),
(2, 'USB数据线采购',    'Type-C转USB-A，1米长度',                         '电子元器件', 10000, '条', 'OPEN',   DATEADD('DAY', 15, NOW())),
(3, '塑料收纳盒采购',   'PP材质，透明，多规格',                            '塑料制品',   20000, '个', 'QUOTED', DATEADD('DAY', 20, NOW())),
(1, '纸箱包装盒采购',   '三层瓦楞纸，定制尺寸',                            '包装材料',   50000, '个', 'CLOSED', DATEADD('DAY', 25, NOW())),
(2, '手机壳采购',       'TPU材质，多款式',                                 '塑料制品',   30000, '个', 'OPEN',   DATEADD('DAY', 10, NOW()));

-- ==================== 6. 报价 ====================
INSERT INTO t_quotation (inquiry_id, supplier_id, unit_price, total_price, delivery_days, description, status) VALUES
(3, 1, 1.80,  36000.00,  18, '可按时交付，品质保证',  'SUBMITTED'),
(3, 2, 1.95,  39000.00,  15, '品质保证，量大优惠',    'SUBMITTED'),
(1, 1, 24.00, 120000.00, 28, '可定制Logo，304不锈钢', 'SUBMITTED');

-- ==================== 7. 合同 ====================
INSERT INTO t_contract (contract_no, inquiry_id, quotation_id, buyer_id, supplier_id, contract_type, contract_title, total_amount, currency, status, payment_terms) VALUES
('CON20260222001', 4, NULL, 1, 1, 'PURCHASE', '纸箱包装盒采购合同', 37500.00, 'CNY', 'SIGNED',    '30%预付，70%发货前'),
('CON20260221001', 3, 1,    3, 1, 'PURCHASE', '塑料收纳盒采购合同', 36000.00, 'CNY', 'EXECUTING', '50%预付');

-- ==================== 8. 订单 ====================
INSERT INTO t_order (order_no, buyer_id, supplier_id, total_amount, currency, status, payment_status, shipping_address, contact_phone, estimated_delivery_date, remark) VALUES
('ORD20260223001', 1, 1, 37500.00, 'CNY', 'SHIPPED',    'PAID',   '深圳市南山区科技园', '13800138001', DATEADD('DAY', 5, CURRENT_DATE),  '纸箱包装盒订单'),
('ORD20260222001', 3, 1, 36000.00, 'CNY', 'CONFIRMED',  'PAID',   '上海市浦东新区',     '13800138003', DATEADD('DAY', 10, CURRENT_DATE), '塑料收纳盒订单'),
('ORD20260221001', 2, 2, 16000.00, 'CNY', 'COMPLETED',  'PAID',   '广州市天河区CBD',    '13800138002', DATEADD('DAY', -3, CURRENT_DATE), 'USB数据线订单'),
('ORD20260220001', 1, 1, 45000.00, 'CNY', 'PENDING',    'UNPAID', '深圳市南山区科技园', '13800138001', DATEADD('DAY', 15, CURRENT_DATE), '五金配件套装');

-- ==================== 9. 订单明细 ====================
INSERT INTO t_order_item (order_id, product_id, product_name, unit_price, quantity, unit, subtotal) VALUES
(1, NULL, '纸箱包装盒',   0.75,  50000, '个', 37500.00),
(2, NULL, '塑料收纳盒',   1.80,  20000, '个', 36000.00),
(3, NULL, 'USB数据线',    3.20,  5000,  '条', 16000.00),
(4, NULL, '五金配件套装', 45.00, 1000,  '套', 45000.00);

-- ==================== 10. 站内消息 ====================
INSERT INTO t_message (message_no, type, title, content, sender_id, sender_name, receiver_id, receiver_name, is_read, status) VALUES
('MSG20260223001', 'SYSTEM',  '欢迎加入易采贸易平台',         '尊敬的用户，欢迎您注册成为平台会员！',                  NULL, '系统',   1, '系统管理员', FALSE, 'ACTIVE'),
('MSG20260223002', 'ORDER',   '订单ORD20260223001已发货',     '您的订单已发货，物流单号：SF1234567890',                  5,    '陈供应', 1, '张采购',     FALSE, 'ACTIVE'),
('MSG20260223003', 'INQUIRY', '收到新的报价',                 '供应商东莞精密制造厂对您的询价塑料收纳盒采购提交了报价',   5,    '陈供应', 3, '王采购',     FALSE, 'ACTIVE'),
('MSG20260222001', 'SYSTEM',  '系统维护通知',                 '平台将于本周六凌晨2:00-4:00进行系统维护',                NULL, '系统',   2, '李采购',     TRUE,  'ACTIVE'),
('MSG20260222002', 'ORDER',   '订单ORD20260221001已完成',     '您的订单已确认收货完成，感谢您的支持！',                   6,    '刘供应', 2, '李采购',     TRUE,  'ACTIVE');

-- ==================== 11. 行业品类 ====================
INSERT INTO t_industry (name, name_en, sort_order, status) VALUES
('智能匹配',     'Smart Match',      1, 'ACTIVE'),
('电子拍卖',     'Reverse Auction',  2, 'ACTIVE'),
('供应链',       'Supply Chain',     3, 'ACTIVE'),
('安全保障',     'Security',         4, 'ACTIVE'),
('陶瓷制品',     'Ceramics',         5, 'ACTIVE'),
('电子元器件',   'Electronics',      6, 'ACTIVE'),
('五金制品',     'Hardware',         7, 'ACTIVE'),
('塑料制品',     'Plastics',         8, 'ACTIVE');

-- ==================== 12. 平台资讯 ====================
INSERT INTO t_news (news_no, title, summary, content, category, status, lang, industry_id, industry_name, author_name, auto_generated, view_count, is_top, is_recommend, publish_time) VALUES
('NEWS20260306001',
 'How YiCai Structures Supplier Matching',
 'A practical overview of how product requirements are normalized before candidate suppliers are reviewed.',
 '<h2>Start With a Comparable Requirement</h2><p>Useful supplier matching begins with a clear product specification, quantity, target market, compliance documents, delivery window and trade term.</p><h3>How the Workflow Helps</h3><p><strong>1. Requirement normalization:</strong> YiCai organizes materials, dimensions, tolerances, packing and inspection criteria into a common brief.</p><p><strong>2. Candidate review:</strong> Supplier documents and declared capabilities are checked against the brief. Verification depth depends on the project and may include samples or an on-site audit.</p><p><strong>3. Comparable quotations:</strong> Prices are compared only after currency, Incoterm, packing, tooling, tax and inspection scope have been aligned.</p><p><strong>4. Human decision:</strong> Matching suggestions support the sourcing team; they do not replace commercial, quality or compliance review.</p><p><a href="/smart-match.html">Explore the guided matching workflow</a>.</p>',
 'NEWS', 'PUBLISHED', 'en', 1, 'Smart Match', 'YiCai Editorial', FALSE, 0, TRUE, TRUE, TIMESTAMP '2026-07-15 10:00:00'),

('NEWS20260305001',
 'A Practical Guide to Electronic Reverse Auctions',
 'See when timed supplier bidding is useful and why the lowest number is not automatically the best award decision.',
 '<h2>What a Reverse Auction Does</h2><p>Pre-screened suppliers submit progressively lower quotations during a defined window. It is most useful for repeatable products whose specifications and quotation scope can be frozen before bidding.</p><h3>YiCai Workflow</h3><p><strong>Step 1:</strong> Confirm specifications, quantity, compliance, inspection, packing, currency and Incoterm.</p><p><strong>Step 2:</strong> Invite suppliers whose documents and capabilities fit the project.</p><p><strong>Step 3:</strong> Run anonymous timed bidding with a minimum decrement and an auditable event log.</p><p><strong>Step 4:</strong> Review price together with lead time, sample result, capacity and commercial risk before issuing a purchase order.</p><p>Results vary by product and market conditions. Demonstration prices on this site are labelled as examples and are not performance claims.</p>',
 'NEWS', 'PUBLISHED', 'en', 2, 'Reverse Auction', 'YiCai Editorial', FALSE, 0, FALSE, TRUE, TIMESTAMP '2026-07-15 09:00:00'),

('NEWS20260304001',
 'Sourcing Across China''s Manufacturing Clusters',
 'An introduction to common production clusters and the checks needed before a factory is approved for a project.',
 '<h2>Choose the Cluster, Then Verify the Factory</h2><p>China''s manufacturing capabilities are distributed across specialized regional clusters. Chaozhou and Dehua are known for ceramics, Shenzhen and Dongguan for electronics, Ningbo and Foshan for hardware, and the Yangtze River Delta for packaging and fabrication.</p><h3>Project-Specific Qualification</h3><p>A supplier name in a resource pool is only a starting point. Depending on project risk, YiCai may review the business licence, export capability, relevant certificates, equipment list, production samples, capacity evidence and quality records.</p><p>Factory status and documentation can change. Final approval is tied to the specific product, customer market and current evidence rather than a permanent platform-wide guarantee.</p>',
 'NEWS', 'PUBLISHED', 'en', 3, 'Supply Chain', 'YiCai Editorial', FALSE, 0, FALSE, TRUE, TIMESTAMP '2026-07-15 08:30:00'),

('NEWS20260303001',
 'How Payments Work When YiCai Is the Contracting Seller',
 'Customer collection and supplier settlement are two separate contractual payment flows.',
 '<h2>A Direct Sales Model</h2><p>The overseas customer contracts with and pays YiCai for the goods and agreed services. YiCai separately contracts with the selected supplier and pays that supplier against the procurement purchase order, inspection evidence and agreed milestones.</p><h3>Important Boundaries</h3><p>Customer receipts enter YiCai''s merchant account through the payment method shown in the signed order or checkout. Available methods depend on the contracted bank or licensed payment provider and the buyer''s country.</p><p>This is not a marketplace escrow service, and customer money is not automatically split or released to a third-party seller. Delivery, inspection, cancellation and refund rights are governed by the customer''s sales contract with YiCai.</p><p>Any payment provider shown as planned is not available until account approval, technical integration and commercial terms are complete.</p>',
 'NEWS', 'PUBLISHED', 'en', 4, 'Payments', 'YiCai Editorial', FALSE, 0, FALSE, FALSE, TIMESTAMP '2026-07-15 14:00:00');

-- ==================== 13. 产品数据 ====================
INSERT INTO t_product (product_no, name, supplier_id, supplier_name, category, price, min_order_quantity, unit, stock, description, image_url, audit_status) VALUES
('PRD20260001', '高精度温湿度传感器 A200',   5, '深圳传感科技有限公司',   '电子元器件',   128.00, 100,  '个', 5000,  '工业级高精度温湿度传感器，RS485通讯接口，精度±0.1°C', NULL, 'APPROVED'),
('PRD20260002', '不锈钢精密螺丝套装 M3-M8', 6, '东莞精密制造厂',         '五金制品',     45.00,  500,  '套', 10000, '304不锈钢精密螺丝套装，含M3/M4/M5/M6/M8规格',       NULL, 'APPROVED'),
('PRD20260003', 'LED工业照明灯管 T8',        5, '深圳传感科技有限公司',   '电子元器件',   35.50,  200,  '支', 8000,  '36W工业级LED灯管，6500K冷白光，寿命50000小时',       NULL, 'APPROVED'),
('PRD20260004', '环保纸箱包装盒 350×250',    7, '浙江包装材料有限公司',   '塑料制品',     0.75,   5000, '个', 100000,'三层瓦楞纸箱，350×250×200mm，环保印刷',              NULL, 'APPROVED'),
('PRD20260005', 'USB Type-C数据线 1.5m',     6, '东莞精密制造厂',         '电子元器件',   3.20,   1000, '条', 50000, '快充3A USB-C数据线，尼龙编织，1.5米长',              NULL, 'APPROVED'),
('PRD20260006', '陶瓷马克杯 350ml定制',      7, '浙江包装材料有限公司',   '陶瓷制品',     8.50,   500,  '个', 20000, '白色陶瓷马克杯350ml，可定制LOGO印刷',                NULL, 'APPROVED'),
('PRD20260007', '铝合金散热片 80×60mm',      5, '深圳传感科技有限公司',   '五金制品',     12.00,  200,  '片', 15000, '6063铝合金散热片，阳极氧化处理，80×60×25mm',         NULL, 'APPROVED'),
('PRD20260008', 'PE塑料收纳盒 大号',         7, '浙江包装材料有限公司',   '塑料制品',     1.80,   2000, '个', 30000, 'PE环保塑料收纳盒，450×300×200mm，透明可叠放',        NULL, 'APPROVED');

-- ==================== 14. 押金系统配置 ====================
INSERT INTO t_auction_deposit_config (config_key, config_value, description) VALUES
('BUYER_DEPOSIT_AMOUNT',      '50.00', '采购商发布反拍押金(USD)'),
('SUPPLIER_DEPOSIT_AMOUNT',   '10.00', '供应商竞拍押金(USD)'),
('DEPOSIT_CURRENCY',          'USD',   '押金币种'),
('BUYER_REGISTER_VOUCHERS',   '3',     '新用户(采购商)注册赠送押金抵用券数量'),
('SUPPLIER_REGISTER_VOUCHERS','10',    '供应商注册赠送拍卖押金抵用券数量'),
('VOUCHER_VALIDITY_DAYS',     '365',   '抵用券有效期(天)'),
('DEPOSIT_REFUND_DAYS',       '7',     '拍卖结束后押金退还期限(天)'),
('AUTO_REFUND_ON_COMPLETE',   'true',  '拍卖完成后是否自动退还押金');

-- ==================== 15. 演示用押金抵用券 ====================
-- 采购商buyer1(userId=2)注册赠送3张$50抵用券
INSERT INTO t_deposit_voucher (voucher_no, user_id, user_type, voucher_type, face_value, currency, status, source, expires_at, remark) VALUES
('VCH20260301001', 2, 'BUYER', 'BUYER_DEPOSIT', 50.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260301002', 2, 'BUYER', 'BUYER_DEPOSIT', 50.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260301003', 2, 'BUYER', 'BUYER_DEPOSIT', 50.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券');
-- 采购商buyer2(userId=3)注册赠送3张$50抵用券
INSERT INTO t_deposit_voucher (voucher_no, user_id, user_type, voucher_type, face_value, currency, status, source, expires_at, remark) VALUES
('VCH20260302001', 3, 'BUYER', 'BUYER_DEPOSIT', 50.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260302002', 3, 'BUYER', 'BUYER_DEPOSIT', 50.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260302003', 3, 'BUYER', 'BUYER_DEPOSIT', 50.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券');
-- 供应商supplier1(userId=5)注册赠送10张$10抵用券
INSERT INTO t_deposit_voucher (voucher_no, user_id, user_type, voucher_type, face_value, currency, status, source, expires_at, remark) VALUES
('VCH20260305001', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305002', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305003', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305004', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305005', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305006', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305007', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305008', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305009', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260305010', 5, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券');
-- 供应商supplier2(userId=6)注册赠送10张$10抵用券
INSERT INTO t_deposit_voucher (voucher_no, user_id, user_type, voucher_type, face_value, currency, status, source, expires_at, remark) VALUES
('VCH20260306001', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306002', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306003', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306004', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306005', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306006', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306007', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306008', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306009', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券'),
('VCH20260306010', 6, 'SUPPLIER', 'SUPPLIER_DEPOSIT', 10.00, 'USD', 'ACTIVE', 'REGISTER', TIMESTAMP '2027-03-13 00:00:00', '注册赠送押金抵用券');
