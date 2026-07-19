# International payment setup

## Current commercial model

YiCai is the contracting seller for overseas customer orders. The overseas buyer pays YiCai under YiCai's sales contract and invoice; YiCai separately purchases from and settles with the selected Chinese supplier under a procurement contract. Customer funds are therefore merchant sales receipts, not marketplace funds held on behalf of third-party sellers.

WorldFirst/WorldTrade is the preferred cross-border collection option, but it must remain labelled as planned until the merchant account, supported transaction flow, API access and contract wording are approved. Never present an uncontracted provider or a normal merchant account as licensed escrow.

The application supports two online collection channels for overseas buyers:

- Stripe Checkout (`STRIPE`) for cards and payment methods dynamically enabled in the Stripe Dashboard.
- PayPal Orders v2 (`PAYPAL`) for PayPal wallet and eligible regional funding sources.

International wire transfer (`TT_TRANSFER`) and letter of credit (`LETTER_OF_CREDIT`) create pending records only. They require an administrator to verify bank documents and incoming funds.

## Stripe

Set these environment variables on the backend service:

```text
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_SUCCESS_URL=https://your-domain.example/user-center.html
STRIPE_CANCEL_URL=https://your-domain.example/user-center.html
```

Create a Stripe webhook endpoint pointing to:

```text
https://your-domain.example/api/payments/callback/stripe
```

Subscribe to `checkout.session.completed` and `checkout.session.async_payment_succeeded`. The application verifies the raw request body, `Stripe-Signature`, timestamp tolerance, payment binding, amount and currency before marking an order paid.

## PayPal

Set:

```text
PAYPAL_CLIENT_ID=...
PAYPAL_CLIENT_SECRET=...
PAYPAL_MODE=live
```

Use `PAYPAL_MODE=sandbox` with Sandbox credentials during testing. The browser obtains the public Client ID from the authenticated backend; no merchant credential is stored in HTML or JavaScript.

## Settlement boundary

These integrations collect customer sales proceeds into YiCai's merchant account. Supplier payment is a separate accounts-payable workflow backed by YiCai's supplier contract, inspection record and purchase order. The application must not automatically split or transfer the customer's receipt to a supplier.

If the platform later allows independent third-party sellers to contract directly with buyers, the current payment model is no longer sufficient. That marketplace model requires a licensed marketplace payment/payout product plus KYC/KYB, sanctions screening, chargeback handling, safeguarded or segregated funds where required, multi-currency ledger accounts and country-specific legal review before supplier payouts are enabled.

Never mark an online payment paid from a browser return page. Stripe is confirmed only by a signed webhook, and PayPal is confirmed only after the backend captures and validates the provider response.
