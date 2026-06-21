# Threat Model: Financial Trading Platform
 
## System Overview
 
A trading platform enabling users to view real-time stock prices, execute buy/sell orders, transfer funds, and set automated trading rules. Requirements: 99.99% uptime, <100ms latency for trades, regulatory compliance (SEC, FINRA).
 
---
 
## Question 1: Most Critical CIA Component and Security vs. Performance Conflicts
 
### Most Critical CIA Component: Integrity
 
**Reasoning:**
 
In a financial trading platform, **Integrity** is the most critical CIA component. Here is the comparative analysis:
 
**Integrity (MOST CRITICAL)**
Financial trading is built entirely on the trustworthiness of data. If trade prices, order quantities, account balances, or transaction records are tampered with — even by a single digit — the consequences are catastrophic and potentially irreversible:
- An order for 100 shares modified to 10,000 shares causes massive financial loss
- A sell order changed to a buy order exploits a user against their intent
- Modified transaction records constitute financial fraud and market manipulation
- Regulatory bodies (SEC, FINRA) impose strict penalties for data integrity failures
The 2010 Flash Crash demonstrated how corrupted data flows and erroneous orders can cause a $1 trillion market value loss in minutes. Data integrity failures in trading are not recoverable by simply "changing the password."
 
**Confidentiality (HIGH)**
Trading strategies and positions are sensitive competitive information. Exposure of a hedge fund's trading algorithm or a large pending order could enable front-running (trading ahead of the order to profit). However, while serious, a confidentiality breach does not directly corrupt the system's operation.
 
**Availability (HIGH)**
The 99.99% uptime requirement (~52 minutes downtime/year) reflects the importance of availability. Platform downtime during active trading means users cannot execute orders, causing financial loss. However, brief downtime, while costly, is preferable to a system that is "available" but processing corrupted data.
 
### Conclusion
The hierarchy for this system: **Integrity > Availability > Confidentiality**
 
A system that is highly available but processing tampered trades is more dangerous than one that is temporarily unavailable.
 
---
 
### Can Security Requirements Conflict with Performance Requirements?
 
**Yes — and this platform has several explicit tensions:**
 
**Conflict 1: Encryption vs. Latency**
- Security requirement: Encrypt all trade data in transit and at rest (TLS, AES-256)
- Performance requirement: <100ms trade execution latency
- Tension: TLS handshake adds 50-200ms; database encryption adds query overhead
- Resolution: Use TLS 1.3 (faster handshake than 1.2), hardware encryption accelerators (AES-NI), connection pooling to amortize TLS overhead, keep encryption keys in HSM with low-latency access
**Conflict 2: Audit Logging vs. Throughput**
- Security requirement: Log every trade for SEC/FINRA compliance (immutable audit trail)
- Performance requirement: High-frequency trading requires processing thousands of orders per second
- Tension: Synchronous logging to immutable store adds write latency per transaction
- Resolution: Asynchronous logging with guaranteed delivery (Kafka, write-ahead log); accept that logs may be slightly delayed but guaranteed to arrive; never sacrifice trade execution speed for synchronous logging
**Conflict 3: Fraud Detection vs. Trade Speed**
- Security requirement: Real-time anomaly detection to catch fraudulent trades
- Performance requirement: <100ms execution
- Tension: ML-based fraud scoring can take 50-500ms per transaction
- Resolution: Run fraud detection in parallel with order processing for small trades; implement pre-computation of user risk scores; use lightweight rule-based checks in the critical path, full ML model asynchronously
**Conflict 4: Session Timeout vs. Trader Experience**
- Security requirement: Short session timeouts to limit exposure of compromised sessions
- Performance requirement: Active traders need persistent sessions during trading hours
- Resolution: Activity-based session extension (session renewed on each trade action); step-up authentication for high-value actions (transfers over $10,000); absolute maximum session length of 8 hours
---
 
## Question 2: Threat Model — Automated Trading Rules Feature
 
### Feature Description
Users define rules that execute trades automatically: "If AAPL drops below $150, buy 100 shares" or "If portfolio gains 15%, sell all positions."
 
---
 
### Top Risk 1: Logic Injection / Rule Manipulation (CRITICAL)
 
**STRIDE Category:** Tampering + Elevation of Privilege
 
**Threat Description:**
An attacker manipulates automated trading rule parameters to cause unintended large trades. By exploiting insufficient validation of rule conditions, an attacker crafts rules that trigger in unexpected market conditions, causing massive financial loss.
 
**Attack Scenario:**
```
Attacker accesses rule creation API endpoint
→ Creates rule with manipulated parameters:
  {"condition": "price < 999999", "action": "buy", "quantity": 1000000}
→ Rule triggers immediately (price always below 999999)
→ Platform attempts to execute buy order for 1,000,000 shares
→ Order exceeds account balance but platform processes partial fill
→ User incurs massive debt or exchange rejects order affecting market
```
 
**Real-World Parallel:** The Knight Capital incident (2012) — a software bug in automated trading caused $440 million loss in 45 minutes.
 
**DREAD Score:**
| Factor | Score | Justification |
|--------|-------|--------------|
| Damage | 10 | Complete financial ruin; regulatory violation |
| Reproducibility | 8 | Repeatable with crafted rule parameters |
| Exploitability | 6 | Requires understanding of trading API |
| Affected Users | 7 | Can affect specific user or market broadly |
| Discoverability | 7 | API endpoints discoverable via documentation |
| **Total** | **7.6** | **HIGH RISK** |
 
**Mitigations:**
1. Enforce strict server-side validation of all rule parameters (quantity limits, price range validation, condition logic bounds)
2. Implement maximum trade size limits per rule (e.g., no single automated rule can execute more than 5% of account value)
3. Require human confirmation for rules exceeding defined thresholds
4. Implement circuit breakers that pause automated trading if unusual volume is detected
5. Sandbox rule execution — test rule against historical data before activating
---
 
### Top Risk 2: Race Conditions in Concurrent Rule Execution (HIGH)
 
**STRIDE Category:** Tampering
 
**Threat Description:**
Multiple trading rules execute simultaneously against the same account balance, creating a race condition where each rule "sees" the full available balance and all execute, resulting in over-commitment of funds.
 
**Attack Scenario:**
```
User has $50,000 balance
Rule A: "If AAPL drops 5%, buy $45,000 of AAPL"
Rule B: "If TSLA drops 5%, buy $45,000 of TSLA"
→ Both stocks drop simultaneously
→ Rule A and Rule B both read balance: $50,000 ✓
→ Rule A executes: buys $45,000 AAPL, balance should be $5,000
→ Rule B executes concurrently: reads $50,000 (before Rule A deducted)
→ Buys $45,000 TSLA → account goes to -$40,000
→ User owes broker $40,000 they don't have
```
 
**DREAD Score:**
| Factor | Score | Justification |
|--------|-------|--------------|
| Damage | 8 | User debt, broker liability, potential margin calls |
| Reproducibility | 7 | Reproducible under volatile market conditions |
| Exploitability | 5 | Difficult to intentionally trigger, may occur naturally |
| Affected Users | 6 | Affects users with multiple rules on same balance |
| Discoverability | 4 | Race condition requires technical knowledge to identify |
| **Total** | **6.0** | **HIGH RISK** |
 
**Mitigations:**
1. Implement atomic balance reservation: before rule triggers, atomically lock required funds
2. Use database transactions with SERIALIZABLE isolation level for all balance operations
3. Implement optimistic locking with version numbers on account balance records
4. Queue rule executions through a single-threaded rule executor per account
5. Test concurrent execution scenarios in staging environment before production deployment
---
 
### Top Risk 3: Unauthorized Rule Modification (HIGH)
 
**STRIDE Category:** Spoofing + Tampering
 
**Threat Description:**
An attacker modifies another user's automated trading rules through an IDOR (Insecure Direct Object Reference) vulnerability, causing their rules to execute harmful trades.
 
**Attack Scenario:**
```
Victim's rule: /api/trading-rules/78234 → "Buy AAPL if price < $150"
Attacker modifies API request to: /api/trading-rules/78234
→ API lacks proper authorization check
→ Attacker changes rule: "Sell ALL positions if price > $0.01"
→ Rule triggers immediately
→ Victim's entire portfolio liquidated without consent
→ Attacker may profit by short-selling victim's stocks before triggering rule
```
 
**DREAD Score:**
| Factor | Score | Justification |
|--------|-------|--------------|
| Damage | 9 | Complete portfolio liquidation; irreversible at market prices |
| Reproducibility | 9 | Fully reproducible if IDOR exists |
| Exploitability | 7 | Requires only rule ID enumeration (easy with sequential IDs) |
| Affected Users | 6 | Targeted attack but scalable to all users |
| Discoverability | 8 | API endpoints discoverable via browser DevTools |
| **Total** | **7.8** | **HIGH RISK** |
 
**Mitigations:**
1. Implement object-level authorization: verify rule ownership on every read/modify request
2. Use UUIDs instead of sequential IDs for all trading rules
3. Log all rule modification attempts with user ID, timestamp, and IP address
4. Send email/push notification to user when any trading rule is modified
5. Require re-authentication (step-up auth) for modifying high-impact rules
---
 
## Question 3: Defense-in-Depth After Account Compromise
 
### Scenario: Attacker Has Valid Username and Password for a User Account
 
The following five layers of security should limit the damage an attacker can cause even with valid credentials:
 
---
 
### Layer 1: Multi-Factor Authentication (MFA)
 
**Control:** Require TOTP or hardware key (YubiKey) for login, even with correct password.
 
**How it limits damage:** Valid credentials alone are insufficient to log in. The attacker needs physical possession of the user's phone or hardware key. This single control stops the majority of credential-based attacks.
 
**Implementation:** TOTP (RFC 6238), backup codes stored securely, step-up MFA for sensitive operations (fund transfers, rule modification)
 
---
 
### Layer 2: Session Management and Anomaly Detection
 
**Control:** Flag and challenge sessions showing anomalous behavior — new device, unusual location, unusual trading volume, after-hours access.
 
**How it limits damage:** Even if attacker bypasses MFA, sessions from new devices/locations are automatically flagged for additional verification. Trading patterns deviating from the user's historical baseline trigger automated holds.
 
**Implementation:**
- Device fingerprinting on every session
- Geolocation checks with alerts for impossible travel (login from New York then Tokyo 1 hour later)
- ML-based behavioral analytics on trading patterns
- Automatic session termination and notification to account owner
---
 
### Layer 3: Transaction Limits and Fund Transfer Controls
 
**Control:** Enforce per-session, per-day, and per-transaction limits on fund withdrawals and trade sizes.
 
**How it limits damage:** Even with full account access, the attacker cannot drain the entire account in a single session. Time-based limits force repeated authentication attempts, increasing detection probability.
 
**Implementation:**
- Daily withdrawal limit: $10,000 (configurable, lower default)
- Per-transaction limit: $50,000 for trades
- Fund transfers to new external accounts: 24-hour delay + email confirmation
- Velocity limits: flag accounts executing >10x normal trading volume
- Cooling-off period for new withdrawal destinations (48 hours)
---
 
### Layer 4: Immutable Audit Trail and Real-Time Alerting
 
**Control:** Log every action in an immutable audit trail and send real-time alerts to the account owner for significant actions.
 
**How it limits damage:** The attacker cannot cover their tracks. All actions are recorded for forensic analysis. The legitimate user receives immediate alerts enabling rapid incident response (calling the broker to freeze the account).
 
**Implementation:**
- Write-once audit logs (WORM storage) retained for 7 years (SEC requirement)
- Real-time email + SMS + push notifications for: login from new device, trade >$5,000, fund withdrawal, rule modification
- SIEM integration for automated threat detection
- 30-second alert delay maximum to enable response before large transactions complete
---
 
### Layer 5: Rapid Account Freeze and Incident Response
 
**Control:** Enable immediate account freeze capability accessible to security team and user, with clear escalation procedures.
 
**How it limits damage:** When an attack is detected (by the user or automated systems), the account can be frozen within seconds, stopping further damage. Clear recovery procedures minimize the window of exploitation.
 
**Implementation:**
- One-click account freeze from mobile app (accessible even without logging in)
- Automated freeze triggers: 5 failed MFA attempts, login from sanctioned country, fraud score >0.9
- Security team can freeze account within 60 seconds of alert
- Frozen account: no trades, no withdrawals, no rule modifications
- Recovery requires: identity verification via video call + government ID
- All transactions during suspicious window flagged for SEC review
---
 
### Defense-in-Depth Summary
 
```
Attack Path:      Credential Compromise
                         ↓
Layer 1 (MFA):   Stopped 99%+ of attackers here
                         ↓
Layer 2 (Session): Flags anomalous behavior, alerts user
                         ↓
Layer 3 (Limits):  Caps financial damage to configured limits
                         ↓
Layer 4 (Audit):   Records all activity, enables forensics
                         ↓
Layer 5 (Freeze):  Stops attack within seconds of detection
```
 
Even if an attacker breaches all five layers, the combination of transaction limits and rapid freeze means the maximum financial damage is bounded and the attacker's window is measured in seconds, not hours.
 
---
 
*Threat model created following SEC/FINRA cybersecurity guidelines, NIST SP 800-53, and OWASP Application Security Verification Standard (ASVS).*

