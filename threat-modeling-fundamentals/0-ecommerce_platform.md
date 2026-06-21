# Threat Model: E-Commerce Platform
 
## System Overview
 
An e-commerce platform with React frontend, Node.js API backend, PostgreSQL database, and Stripe payment integration. Users can browse products (unauthenticated), add to cart (unauthenticated), and checkout/view order history (authenticated).
 
---
 
## Question 1: Three STRIDE Threats for the Checkout Process
 
### Threat 1 — Tampering (Price Manipulation)
 
**STRIDE Category:** Tampering
 
**Threat Description:**
An attacker intercepts or modifies the HTTP request during checkout, changing the product price before it reaches the backend. For example, a product priced at $500 is modified to $0.01 in the request payload before submission.
 
**Attack Scenario:**
```
User adds item ($500) to cart
→ Attacker intercepts POST /api/checkout request via browser dev tools
→ Modifies {"price": 500} to {"price": 0.01}
→ Backend trusts client-supplied price
→ Stripe charges $0.01 instead of $500
```
 
**Potential Impact:**
- Direct financial loss to the business
- Revenue fraud at scale if automated
- Reputational damage if discovered by partners
**Suggested Mitigation:**
- Never trust client-supplied prices; always recalculate total server-side from the product database
- Implement server-side cart validation before any payment processing
- Log and alert on price discrepancies between client and server calculations
---
 
### Threat 2 — Information Disclosure (Payment Data Interception)
 
**STRIDE Category:** Information Disclosure
 
**Threat Description:**
Payment card data (PAN, CVV, expiry) is transmitted in plaintext or logged in server logs, exposing sensitive financial data to unauthorized parties.
 
**Attack Scenario:**
```
User submits checkout form with card details
→ Application logs full request body for debugging
→ Attacker gains access to log files (via LFI, misconfiguration, or insider threat)
→ Extracts thousands of card numbers from logs
→ Sells or uses stolen card data
```
 
**Potential Impact:**
- PCI-DSS violation with fines up to $500,000 per incident
- Mass financial fraud affecting all customers who checked out
- Legal liability and potential class-action lawsuits
**Suggested Mitigation:**
- Use Stripe.js to tokenize card data client-side; backend never receives raw card numbers
- Ensure TLS 1.2+ on all endpoints
- Sanitize all logs to remove card data, CVV, and full PANs
- Implement PCI-DSS compliant logging practices
---
 
### Threat 3 — Elevation of Privilege (Checkout Without Authentication)
 
**STRIDE Category:** Elevation of Privilege
 
**Threat Description:**
An attacker bypasses authentication checks on the checkout endpoint, completing a purchase using another user's saved payment method or accessing order details without logging in.
 
**Attack Scenario:**
```
Attacker discovers checkout API endpoint: POST /api/checkout
→ Sends request without valid session token
→ Backend improperly validates authentication (missing middleware)
→ Attacker completes checkout using victim's stored payment method
→ Order placed and shipped to attacker's address
```
 
**Potential Impact:**
- Unauthorized purchases using stolen or stored payment methods
- Access to other users' personal and financial information
- Financial liability and fraud chargebacks
**Suggested Mitigation:**
- Enforce authentication middleware on ALL checkout and order endpoints
- Implement server-side session validation on every protected route
- Use JWT with short expiration times and refresh token rotation
- Add CSRF tokens to all state-changing POST requests
---
 
## Question 2: Trust Boundaries
 
### Trust Boundary 1: Browser (User) → Node.js API Backend
 
**Description:** The boundary between the React frontend running in the user's browser and the Node.js API server. This is the most critical trust boundary because anything originating from the browser is completely untrusted.
 
**Data crossing this boundary:**
- Product search queries
- Cart contents and quantities
- Authentication credentials (username/password)
- Checkout form data
**Risks:** Price manipulation, XSS payloads, authentication bypass, CSRF attacks
 
**Controls:** Input validation, HTTPS/TLS, CSRF tokens, JWT authentication, rate limiting
 
---
 
### Trust Boundary 2: Node.js API Backend → PostgreSQL Database
 
**Description:** The boundary between the application server and the database. Even though both are internal components, the database should never trust queries containing unsanitized user input.
 
**Data crossing this boundary:**
- SQL queries constructed from user input
- Product search terms
- User credentials for lookup
- Order data for storage
**Risks:** SQL injection, unauthorized data access, data exfiltration
 
**Controls:** Parameterized queries/prepared statements, principle of least privilege on DB user, connection pooling with authentication, network-level firewall restricting DB access to API only
 
---
 
### Trust Boundary 3: Node.js API Backend → Stripe Payment API
 
**Description:** The boundary between the internal backend and the external Stripe payment processing service. Data crossing this boundary includes sensitive financial information and must be strictly controlled.
 
**Data crossing this boundary:**
- Payment tokens (from Stripe.js)
- Order amounts (server-calculated)
- Customer billing information
- Webhook events (inbound from Stripe)
**Risks:** Man-in-the-middle attacks on outbound requests, webhook spoofing (fake payment confirmation), API key compromise
 
**Controls:** Validate Stripe webhook signatures using the webhook secret, store Stripe API keys in environment variables (never in code), verify TLS certificates on outbound connections, whitelist Stripe's IP ranges for webhooks
 
---
 
### Trust Boundary 4: Authenticated User → Unauthenticated User
 
**Description:** The logical boundary between operations that require authentication (checkout, order history) and those that don't (browse, add to cart). This boundary exists within the application layer.
 
**Risks:** Privilege escalation, unauthorized access to protected resources
 
**Controls:** Role-based access control (RBAC), middleware authentication checks on every protected route, JWT token validation
 
---
 
## Question 3: DREAD Scoring — SQL Injection in Product Search
 
### Vulnerability: SQL Injection in Product Search Functionality
 
**Vulnerable scenario:**
```javascript
// VULNERABLE CODE
const query = `SELECT * FROM products WHERE name LIKE '%${req.query.search}%'`;
```
 
---
 
### DREAD Scoring
 
| Factor | Score (0-10) | Justification |
|--------|-------------|---------------|
| **Damage Potential** | 9 | Full database compromise possible. Attacker can extract all user PII, passwords, payment tokens, and order history. Could also DROP tables, destroying all data. |
| **Reproducibility** | 8 | Once the injection point is identified, the attack is highly reproducible. Automated tools like sqlmap can exploit it reliably every time. |
| **Exploitability** | 7 | Requires basic knowledge of SQL injection syntax. Free tools (sqlmap, Burp Suite) automate the exploitation. No special access required beyond a browser. |
| **Affected Users** | 9 | The product search is available to ALL users including unauthenticated visitors. A successful attack exposes all 100% of user data in the database. |
| **Discoverability** | 9 | The search bar is prominently displayed on the homepage and requires no authentication. Any visitor or automated scanner can discover and test it immediately. |
 
### DREAD Calculation
 
```
DREAD Score = (Damage + Reproducibility + Exploitability + Affected Users + Discoverability) / 5
DREAD Score = (9 + 8 + 7 + 9 + 9) / 5
DREAD Score = 42 / 5
DREAD Score = 8.4 / 10 → CRITICAL RISK
```
 
### Risk Rating: CRITICAL (8.4/10)
 
### Recommended Mitigations (Priority Order):
 
1. **Immediate:** Replace all raw string concatenation with parameterized queries
```javascript
// SECURE CODE
const query = 'SELECT * FROM products WHERE name LIKE $1';
const result = await db.query(query, [`%${searchTerm}%`]);
```
 
2. **Short-term:** Implement a Web Application Firewall (WAF) to detect and block SQL injection patterns
3. **Short-term:** Apply principle of least privilege — the database user used by the application should have SELECT-only access on the products table, not full database privileges
4. **Long-term:** Implement regular automated SQL injection scanning in the CI/CD pipeline using tools like sqlmap or OWASP ZAP
---
 
*Threat model created following STRIDE methodology and DREAD risk assessment framework.*

