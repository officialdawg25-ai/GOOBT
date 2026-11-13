# South African compliance readiness checklist — GOOBT

**Purpose:** engineering/product readiness tracker to take to South African legal, tax and compliance advisers. This is not legal advice and does not decide whether GOOBT or a division is a supplier, marketplace operator, agent, merchant of record, responsible party, operator, or payment facilitator. Those classifications depend on the actual business model and agreements.

## A. Legal entities, seller and marketplace accountability — BLOCKING
- [ ] Confirm GOOBT operating legal entity, registration, address for service, contact details and accountable office bearers.
- [ ] Confirm each division is a brand/trading division versus a separate legal seller; do not treat a division slug as proof of legal identity.
- [ ] For every merchant/seller, collect and independently verify legal name, registration/sole-proprietor status, physical/service address, contact details, bank beneficiary identity, tax/VAT status and product-specific evidence.
- [ ] Determine who is the seller/supplier for each item and customer contract: merchant, GOOBT, or another party. Make that clear before customers can transact.
- [ ] Decide platform role in advertising, checkout, collection, delivery, customer complaints, returns, warranties and refunds; allocate obligations contractually and operationally.
- [ ] Approve marketplace terms, merchant agreement, customer terms, refund/cancellation policy, complaint/escalation process, seller suspension policy and dispute ownership.
- [ ] Have adviser review Consumer Protection Act (CPA) application and ECT Act e-commerce disclosure/order-review/cooling-off rules for each relevant product/service type and transaction.
- [ ] Determine CGSO/NCC participation, membership or complaint-resolution requirements for the actual sellers and platform structure.

## B. ECT Act / online transaction disclosures — BLOCKING before checkout
For each relevant supplier listing/checkout experience, legal review should confirm availability of the applicable disclosures, including:
- [ ] Supplier full name and legal status; physical address and telephone number; website and email contact.
- [ ] Legal entity registration details and office-bearer/place-of-registration disclosures where applicable; physical address for legal service.
- [ ] Main product/service characteristics sufficient for informed purchase.
- [ ] Full price with transport, tax and other charges clearly allocated; avoid uncalculated shipping/tax at final order.
- [ ] Payment method and relevant security/privacy information.
- [ ] Terms, guarantees, delivery/fulfilment timelines, access to transaction records, return/exchange/refund policy and recurring-term disclosures where relevant.
- [ ] Customer can review the complete order, correct mistakes and withdraw before placing the order.
- [ ] Applicability and exceptions of cooling-off/return rules are reviewed per category (e.g. made-to-order, rapidly perishable goods or dated services may have different treatment; do not encode blanket exceptions without advice).
- [ ] Customer receives a durable order confirmation/record, receipt/invoice as assigned by the legally responsible supplier, and clear post-sale contact path.

## C. POPIA and PAIA — BLOCKING before real personal data processing at scale
- [ ] Identify responsible party/parties and operator relationships across GOOBT, each seller, Supabase, Cloudflare, payment provider, notification provider and CozyWash (when integrated).
- [ ] Register/confirm Information Officer and deputy roles as required; assign a person responsible for requests, regulator liaison, privacy framework and impact assessments.
- [ ] Prepare and make available an appropriate PAIA manual and customer privacy notice; describe purposes, lawful bases, categories, recipients/operators, retention, data-subject rights, contact and cross-border transfer arrangements.
- [ ] Maintain a data inventory, processing register, data-flow map and privacy impact assessment, including merchant/customer separation, customer support, identity linking, payment references, delivery addresses, vehicle identifiers and uploaded media.
- [ ] Apply purpose limitation, minimum necessary collection, retention/deletion schedules, access/correction workflows and lawful marketing consent/opt-out handling.
- [ ] Execute written operator/data-processing agreements and verify safeguards with service providers. Review cross-border transfers and POPIA section 72 applicability rather than assuming provider region resolves it.
- [ ] Assess POPIA section 57 prior-authorisation triggers where applicable, including particular unique-identifier processing/linking and special/children's personal information; obtain specialist review before such processing.
- [ ] Document security risk assessment, role-based access, RLS tests, encryption, secret management, backups, restoration, logging, incident response and operator breach-notification procedure.
- [ ] Establish security-compromise response and Information Regulator/data-subject notification process; validate timelines and reporting channel with the Information Officer/adviser.
- [ ] Avoid collection of children’s information, special personal information or unnecessary identity data until lawful purpose, authority and controls are approved.

## D. Merchant/division-specific compliance — BLOCKING by product category
- [ ] **GREYLIN HARVEST / BAKE MY DAY:** identify whether each food seller, production premises, transport and food-handling activity requires a Certificate of Acceptability under applicable hygiene regulations (including R638), municipal approvals, food labelling, traceability, allergen, shelf-life and storage controls. Verify with local Environmental Health Practitioner/municipality.
- [ ] **OPULENCE COSMETICS:** verify product classification, manufacturer/importer obligations, ingredients, labelling, claims/advertising, safety/quality evidence and any applicable Department of Health/Sahpra or other regulatory requirements. Do not make therapeutic/medical claims without classification/adviser review.
- [ ] **OCEANBREEZE:** determine category-specific safety, consumer disclosures, import/export, warranty and restricted-item controls for each product family before enabling listings.
- [ ] Keep proof documents, expiry dates, responsible seller and product approvals linked to the seller/product record; require review before publishing affected goods.
- [ ] Ensure product advertising, prices, origin, stock availability, reviews and testimonials are truthful and substantiated; no fabricated claims.

## E. Tax, VAT, invoicing and accounting — BLOCKING
- [ ] Adviser determines income tax, turnover tax, VAT and other obligations per legal entity and transaction role; decide who issues the customer invoice and seller tax invoice.
- [ ] Ensure the product pricing model correctly treats VAT-inclusive/exclusive prices for each VAT-registered seller, delivery fees, platform commission, discounts, refunds and payment fees.
- [ ] Current SARS published guidance states it is administering a VAT compulsory registration threshold of R2.3 million and voluntary threshold of R120,000 from 1 April 2026, while noting amendments had not yet been promulgated in its FAQs. Confirm current law/thresholds and applicability with SARS/adviser before encoding.
- [ ] Define seller payout/settlement statements, marketplace commission statements, refund/chargeback accounting, reconciliation and record-retention rules.
- [ ] Do not assume GOOBT may collect, hold, split or disburse independent sellers' money; payment-provider and legal approval required.

## F. Payments, settlement, consumer refunds and complaints — BLOCKING
- [ ] Written payment-provider approval for marketplace flow, merchant onboarding, subaccounts/splits, settlements and seller payout eligibility.
- [ ] Decide merchant of record, fee bearer, seller-of-record, refunds, partial refunds, chargebacks, negative balance recovery, cancellation, failed payment and settlement-delay handling.
- [ ] Verify webhook signature, idempotency, replay protection, transaction reconciliation, immutable payment ledger and audit logs in provider sandbox.
- [ ] Define customer service contact, complaint intake, service-level expectations, dispute escalation, returns and refund decision authority.
- [ ] Separate provider's payment status from fulfillment state; never mark orders paid or fulfilled based on browser redirect alone.

## G. Production security, governance and evidence — BLOCKING
- [ ] Complete authenticated/anonymous/customer/merchant/platform-role RLS tests and adversarial tenant isolation tests.
- [ ] Complete checkout/order concurrency, inventory reservation expiry, duplicate request, replay, refund and webhook failure tests before transactional checkout is enabled.
- [ ] Approve production domain, legal notices, provider credentials, environment isolation, monitoring, alerting, backup/restore, incident and rollback procedures.
- [ ] Complete mobile/desktop browser visual QA, accessibility, real customer/seller UAT and documented release approval.
- [ ] Keep deployment production gate disabled until every applicable gate is signed off.

## Official/primary references
- POPIA Act: https://www.gov.za/documents/protection-personal-information-act
- Information Regulator POPIA guidance and Information Officer/PAIA resources: https://inforegulator.org.za/popia/ and https://eservices.inforegulator.org.za/
- ECT Act: https://www.gov.za/documents/electronic-communications-and-transactions-act
- Consumer Protection Act: https://www.gov.za/documents/consumer-protection-act
- NCC/CGSO 2026 e-commerce position paper notice: https://thencc.org.za/turning-the-tide-on-unfair-business-practices-in-e-commerce-ncc-and-cgso-release-a-joint-paper-on-consumer-protection-in-e-commerce/
- Foodstuffs, Cosmetics and Disinfectants Act: https://www.gov.za/documents/foodstuffs-cosmetics-and-disinfectants-act-2-jun-1972-0000
- SARS Budget 2026 VAT threshold FAQs: https://www.sars.gov.za/about/sars-tax-and-customs-system/budget/budget-2026-frequently-asked-questions/
- SARS VAT threshold FAQ: https://www.sars.gov.za/faq/what-is-the-new-threshold-for-vat-registration/
