(function (global) {
    'use strict';

    var STORAGE_KEY = 'yicai.auctionDemoAnchor.v2';
    var MAX_ANCHOR_AGE = 12 * 60 * 60 * 1000;

    function getAnchor() {
        var now = Date.now();
        try {
            var stored = Number(global.sessionStorage.getItem(STORAGE_KEY));
            if (Number.isFinite(stored) && stored <= now + 60 * 1000 && now - stored < MAX_ANCHOR_AGE) {
                return stored;
            }
            global.sessionStorage.setItem(STORAGE_KEY, String(now));
        } catch (error) {
            // sessionStorage may be unavailable in hardened browsers; a fresh anchor is safe.
        }
        return now;
    }

    function iso(anchor, offsetMinutes) {
        return new Date(anchor + offsetMinutes * 60 * 1000).toISOString();
    }

    function dateOnly(anchor, offsetDays) {
        var date = new Date(anchor + offsetDays * 24 * 60 * 60 * 1000);
        var year = date.getFullYear();
        var month = String(date.getMonth() + 1).padStart(2, '0');
        var day = String(date.getDate()).padStart(2, '0');
        return year + '-' + month + '-' + day;
    }

    function auctionNo(anchor, sequence) {
        var date = new Date(anchor);
        return 'DEMO-' + date.getFullYear()
            + String(date.getMonth() + 1).padStart(2, '0')
            + String(date.getDate()).padStart(2, '0')
            + '-' + String(sequence).padStart(2, '0');
    }

    function bid(anchor, id, alias, price, sequence, minutesAgo, options) {
        options = options || {};
        return {
            id: 'demo-bid-' + id,
            supplierId: null,
            supplierCompany: alias,
            bidPrice: price,
            totalAmount: options.totalAmount || null,
            promisedDeliveryDays: options.deliveryDays || null,
            bidSequence: sequence,
            isLowest: options.lowest === true,
            isWinner: options.winner === true,
            createdAt: iso(anchor, -minutesAgo)
        };
    }

    function buildAuctions() {
        var anchor = getAnchor();
        var now = Date.now();
        var demos = [
            {
                demo: true,
                demoKey: 'ceramic-mug',
                id: 'demo-ceramic-mug',
                auctionNo: auctionNo(anchor, 1),
                auctionType: 'REVERSE_AUCTION',
                auctionTypeText: '反向竞价',
                currency: 'USD',
                buyerCompany: 'YiCai Global Sourcing Desk',
                customerMarket: 'United States',
                productName: '350 ml stoneware mugs with custom logo',
                productCategory: 'Ceramics & Tableware',
                specification: [
                    'Material: AB-grade stoneware, food-contact compliant',
                    'Capacity: 350 ml; size tolerance: ±3%',
                    'Finish: matte glaze, 2 Pantone colors',
                    'Decoration: 1-position underglaze logo',
                    'Packing: 1 pc / gift box, 24 pcs / export carton',
                    'Compliance: FDA/LFGB test report from the production batch',
                    'Quote basis: FOB Yantian, including export carton and inspection-ready packing'
                ].join('\n'),
                quantity: 12000,
                unit: 'pcs',
                startingPrice: 1.28,
                currentLowestPrice: 1.14,
                referencePrice: 1.31,
                minDecrement: 0.01,
                signupStartTime: iso(anchor, -1440),
                signupEndTime: iso(anchor, -240),
                startTime: iso(anchor, -210),
                endTime: iso(anchor, 105),
                originalEndTime: iso(anchor, 95),
                status: 'ACTIVE',
                statusText: '竞价中',
                signupCount: 7,
                bidCount: 11,
                participantCount: 5,
                minParticipants: 3,
                currentExtensions: 1,
                extensionMinutes: 5,
                extensionTriggerMinutes: 5,
                maxExtensions: 3,
                showRanking: true,
                showLowestPrice: true,
                deliveryAddress: 'FOB Yantian, Shenzhen, China',
                requiredDeliveryDate: dateOnly(anchor, 38),
                paymentTerms: 'Supplier settlement: 30% after PO, 70% after passed pre-shipment inspection',
                remark: 'Pilot sample approval is required before mass production. Prices are normalized to the same FOB scope.',
                bids: [
                    bid(anchor, 1, 'Factory C-27 · Chaozhou', 1.14, 11, 8, { lowest: true, deliveryDays: 32, totalAmount: 13680 }),
                    bid(anchor, 2, 'Factory D-08 · Dehua', 1.16, 10, 21, { deliveryDays: 29, totalAmount: 13920 }),
                    bid(anchor, 3, 'Factory C-11 · Chaozhou', 1.17, 9, 37, { deliveryDays: 30, totalAmount: 14040 }),
                    bid(anchor, 4, 'Factory J-04 · Jingdezhen', 1.19, 8, 55, { deliveryDays: 34, totalAmount: 14280 }),
                    bid(anchor, 1, 'Factory C-27 · Chaozhou', 1.22, 7, 78, { deliveryDays: 32, totalAmount: 14640 }),
                    bid(anchor, 5, 'Factory C-19 · Chaozhou', 1.24, 6, 103, { deliveryDays: 28, totalAmount: 14880 })
                ]
            },
            {
                demo: true,
                demoKey: 'usb-c-cable',
                id: 'demo-usb-c-cable',
                auctionNo: auctionNo(anchor, 2),
                auctionType: 'REVERSE_AUCTION',
                auctionTypeText: '反向竞价',
                currency: 'USD',
                buyerCompany: 'YiCai Global Sourcing Desk',
                customerMarket: 'Germany',
                productName: '100 W braided USB-C to USB-C cable, 2 m',
                productCategory: 'Consumer Electronics',
                specification: [
                    'USB-C to USB-C, PD 3.0, E-marker IC, rated 100 W',
                    'Length: 2.0 m; black rPET braided jacket',
                    'Required tests: continuity, 100% charging test and 5,000-cycle bend test',
                    'Certifications: CE, RoHS and REACH documentation',
                    'Packing: recyclable paper sleeve with EAN label',
                    'Quote basis: FOB Shenzhen, tooling and certification charges itemized separately'
                ].join('\n'),
                quantity: 20000,
                unit: 'pcs',
                startingPrice: 2.05,
                currentLowestPrice: 2.05,
                referencePrice: 2.12,
                minDecrement: 0.02,
                signupStartTime: iso(anchor, -360),
                signupEndTime: iso(anchor, 150),
                startTime: iso(anchor, 180),
                endTime: iso(anchor, 360),
                originalEndTime: iso(anchor, 360),
                status: 'SIGNUP',
                statusText: '报名中',
                signupCount: 5,
                bidCount: 0,
                participantCount: 0,
                minParticipants: 3,
                currentExtensions: 0,
                extensionMinutes: 5,
                extensionTriggerMinutes: 5,
                maxExtensions: 3,
                showRanking: true,
                showLowestPrice: true,
                deliveryAddress: 'FOB Shenzhen, China',
                requiredDeliveryDate: dateOnly(anchor, 31),
                paymentTerms: 'Supplier settlement: 20% after approved golden sample, 80% after inspection',
                remark: 'Factories must submit the E-marker component source and latest compliance reports.',
                bids: []
            },
            {
                demo: true,
                demoKey: 'steel-bracket',
                id: 'demo-steel-bracket',
                auctionNo: auctionNo(anchor, 3),
                auctionType: 'REVERSE_AUCTION',
                auctionTypeText: '反向竞价',
                currency: 'USD',
                buyerCompany: 'YiCai Global Sourcing Desk',
                customerMarket: 'Canada',
                productName: 'Powder-coated steel wall brackets',
                productCategory: 'Metal Fabrication',
                specification: [
                    'Material: Q235 cold-rolled steel, 3.0 mm',
                    'Process: laser cutting, bending, MIG welding and deburring',
                    'Finish: matte black powder coat, 70–90 μm',
                    'Critical tolerance: hole center distance ±0.20 mm',
                    'Inspection: first article report plus AQL 1.5 / 2.5',
                    'Quote basis: FOB Ningbo, packed 8 sets per export carton'
                ].join('\n'),
                quantity: 8000,
                unit: 'sets',
                startingPrice: 4.68,
                currentLowestPrice: 4.31,
                referencePrice: 4.75,
                minDecrement: 0.03,
                signupStartTime: iso(anchor, -1320),
                signupEndTime: iso(anchor, -300),
                startTime: iso(anchor, -165),
                endTime: iso(anchor, 48),
                originalEndTime: iso(anchor, 48),
                status: 'ACTIVE',
                statusText: '竞价中',
                signupCount: 6,
                bidCount: 8,
                participantCount: 4,
                minParticipants: 3,
                currentExtensions: 0,
                extensionMinutes: 5,
                extensionTriggerMinutes: 5,
                maxExtensions: 3,
                showRanking: true,
                showLowestPrice: true,
                deliveryAddress: 'FOB Ningbo, China',
                requiredDeliveryDate: dateOnly(anchor, 35),
                paymentTerms: 'Supplier settlement: 30% after PO, 70% after dimensional and coating inspection',
                remark: 'All quotes must include the dedicated inspection fixture and palletized export packing.',
                bids: [
                    bid(anchor, 31, 'Factory N-16 · Ningbo', 4.31, 8, 6, { lowest: true, deliveryDays: 25, totalAmount: 34480 }),
                    bid(anchor, 32, 'Factory S-09 · Suzhou', 4.35, 7, 18, { deliveryDays: 22, totalAmount: 34800 }),
                    bid(anchor, 33, 'Factory J-18 · Jiaxing', 4.38, 6, 35, { deliveryDays: 24, totalAmount: 35040 }),
                    bid(anchor, 31, 'Factory N-16 · Ningbo', 4.41, 5, 53, { deliveryDays: 25, totalAmount: 35280 }),
                    bid(anchor, 34, 'Factory F-05 · Foshan', 4.47, 4, 76, { deliveryDays: 27, totalAmount: 35760 })
                ]
            },
            {
                demo: true,
                demoKey: 'mailer-box',
                id: 'demo-mailer-box',
                auctionNo: auctionNo(anchor, 4),
                auctionType: 'REVERSE_AUCTION',
                auctionTypeText: '反向竞价',
                currency: 'USD',
                buyerCompany: 'YiCai Global Sourcing Desk',
                customerMarket: 'United Kingdom',
                productName: 'FSC corrugated e-commerce mailer boxes',
                productCategory: 'Packaging',
                specification: 'E-flute corrugated board; 320 × 240 × 100 mm; kraft exterior; 1-color water-based print; FSC Mix documentation; flat packed; FOB Shanghai.',
                quantity: 50000,
                unit: 'pcs',
                startingPrice: 0.51,
                currentLowestPrice: 0.44,
                winningPrice: 0.44,
                referencePrice: 0.53,
                minDecrement: 0.005,
                signupStartTime: iso(anchor, -2880),
                signupEndTime: iso(anchor, -1680),
                startTime: iso(anchor, -1560),
                endTime: iso(anchor, -1320),
                originalEndTime: iso(anchor, -1320),
                status: 'CONFIRMING',
                statusText: '评审中',
                signupCount: 8,
                bidCount: 14,
                participantCount: 6,
                minParticipants: 3,
                currentExtensions: 0,
                deliveryAddress: 'FOB Shanghai, China',
                requiredDeliveryDate: dateOnly(anchor, 24),
                paymentTerms: 'Supplier settlement after artwork approval, production and random inspection',
                remark: 'Lowest price is being reviewed together with board strength, print sample and lead time.',
                bids: [
                    bid(anchor, 41, 'Factory K-12 · Kunshan', 0.44, 14, 1325, { lowest: true, winner: true, deliveryDays: 18, totalAmount: 22000 }),
                    bid(anchor, 42, 'Factory S-21 · Shanghai', 0.445, 13, 1338, { deliveryDays: 16, totalAmount: 22250 }),
                    bid(anchor, 43, 'Factory J-03 · Jiaxing', 0.455, 12, 1355, { deliveryDays: 19, totalAmount: 22750 })
                ]
            },
            {
                demo: true,
                demoKey: 'silicone-set',
                id: 'demo-silicone-set',
                auctionNo: auctionNo(anchor, 5),
                auctionType: 'REVERSE_AUCTION',
                auctionTypeText: '反向竞价',
                currency: 'USD',
                buyerCompany: 'YiCai Global Sourcing Desk',
                customerMarket: 'Australia',
                productName: '12-piece food-grade silicone utensil set',
                productCategory: 'Kitchenware',
                specification: 'LFGB-grade silicone heads; acacia handles; 12-piece set; heat resistance 230°C; custom color and belly band; FOB Shenzhen.',
                quantity: 6000,
                unit: 'sets',
                startingPrice: 6.80,
                currentLowestPrice: 6.80,
                referencePrice: 7.05,
                minDecrement: 0.05,
                signupStartTime: iso(anchor, -240),
                signupEndTime: iso(anchor, 480),
                startTime: iso(anchor, 510),
                endTime: iso(anchor, 690),
                originalEndTime: iso(anchor, 690),
                status: 'PENDING',
                statusText: '即将报名',
                signupCount: 0,
                bidCount: 0,
                participantCount: 0,
                minParticipants: 3,
                currentExtensions: 0,
                deliveryAddress: 'FOB Shenzhen, China',
                requiredDeliveryDate: dateOnly(anchor, 42),
                paymentTerms: 'Supplier settlement subject to LFGB batch test and pre-shipment inspection',
                remark: 'A color-matched pre-production sample is mandatory.',
                bids: []
            },
            {
                demo: true,
                demoKey: 'high-bay-light',
                id: 'demo-high-bay-light',
                auctionNo: auctionNo(anchor, 6),
                auctionType: 'REVERSE_AUCTION',
                auctionTypeText: '反向竞价',
                currency: 'USD',
                buyerCompany: 'YiCai Global Sourcing Desk',
                customerMarket: 'United Arab Emirates',
                productName: '150 W LED UFO high-bay lights',
                productCategory: 'Commercial Lighting',
                specification: '150 W; 5000 K; ≥150 lm/W; IP65; 1–10 V dimming; 5-year warranty; CB/CE/RoHS reports; FOB Shenzhen.',
                quantity: 600,
                unit: 'pcs',
                startingPrice: 43.50,
                currentLowestPrice: 39.80,
                winningPrice: 39.80,
                referencePrice: 44.20,
                minDecrement: 0.20,
                signupStartTime: iso(anchor, -5760),
                signupEndTime: iso(anchor, -4680),
                startTime: iso(anchor, -4560),
                endTime: iso(anchor, -4380),
                originalEndTime: iso(anchor, -4380),
                status: 'COMPLETED',
                statusText: '已完成',
                signupCount: 7,
                bidCount: 12,
                participantCount: 5,
                minParticipants: 3,
                currentExtensions: 0,
                deliveryAddress: 'FOB Shenzhen, China',
                requiredDeliveryDate: dateOnly(anchor, 18),
                paymentTerms: 'Supplier settlement released after passed aging test and pre-shipment inspection',
                remark: 'Award considered price, photometric report, driver brand and warranty response time.',
                bids: [
                    bid(anchor, 61, 'Factory Z-14 · Zhongshan', 39.80, 12, 4390, { lowest: true, winner: true, deliveryDays: 21, totalAmount: 23880 }),
                    bid(anchor, 62, 'Factory S-33 · Shenzhen', 40.10, 11, 4403, { deliveryDays: 18, totalAmount: 24060 }),
                    bid(anchor, 63, 'Factory F-22 · Foshan', 40.45, 10, 4418, { deliveryDays: 20, totalAmount: 24270 })
                ]
            }
        ];

        demos.forEach(function (auction) {
            var deadline = auction.status === 'SIGNUP' ? auction.signupEndTime
                : (auction.status === 'PENDING' ? auction.startTime : auction.endTime);
            auction.remainingSeconds = Math.max(0, Math.floor((new Date(deadline).getTime() - now) / 1000));
            auction.canBid = auction.status === 'ACTIVE' && auction.remainingSeconds > 0;
            auction.canSignup = auction.status === 'SIGNUP' && auction.remainingSeconds > 0;
            auction.estimatedSavings = auction.startingPrice > 0
                ? Math.max(0, ((auction.startingPrice - auction.currentLowestPrice) / auction.startingPrice) * 100)
                : 0;
        });
        return demos;
    }

    function getAuctions() {
        return buildAuctions();
    }

    function getByKey(key) {
        return buildAuctions().find(function (auction) {
            return auction.demoKey === key || auction.id === key;
        }) || null;
    }

    function detailUrl(auction) {
        if (auction && auction.demo) {
            return 'auction-detail.html?demo=' + encodeURIComponent(auction.demoKey);
        }
        return 'auction-detail.html?id=' + encodeURIComponent(String(auction && auction.id || ''));
    }

    function symbol(currency) {
        var symbols = { USD: '$', EUR: '€', GBP: '£', CNY: '¥', JPY: '¥', CAD: 'CA$', AUD: 'A$' };
        return symbols[String(currency || 'CNY').toUpperCase()] || String(currency || '') + ' ';
    }

    function money(value, currency) {
        var number = Number(value);
        if (!Number.isFinite(number)) number = 0;
        return symbol(currency) + number.toLocaleString('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 4
        });
    }

    global.YICAI_AUCTION_DEMO = Object.freeze({
        getAuctions: getAuctions,
        getByKey: getByKey,
        detailUrl: detailUrl,
        symbol: symbol,
        money: money
    });
})(window);
