# Threat Model: Healthcare Mobile App
 
## System Overview
 
A healthcare mobile app (iOS/Android) allowing patients to view medical records, schedule appointments, message healthcare providers, and receive prescription refills. Uses REST API backend, cloud-hosted database, and integration with hospital systems.
 
---
 
## Question 1: Most Critical Asset — CIA Triad Analysis
 
### Most Critical Asset: Patient Medical Records (Protected Health Information — PHI)
 
Patient medical records are the most critical asset in this system. This includes diagnoses, medications, treatment history, lab results, and personal identifiers.
 
### CIA Triad Analysis
 
**Confidentiality (CRITICAL)**
Medical records contain the most sensitive personal information that exists. Unauthorized disclosure of PHI violates HIPAA regulations, with fines ranging from $100 to $50,000 per violation (up to $1.9 million per year per violation category). Beyond legal consequences, exposure of mental health records, HIV status, substance abuse history, or genetic information can cause irreversible harm to a patient's employment, insurance eligibility, and personal relationships. Unlike a compromised password that can be changed, a leaked diagnosis cannot be "undone."
 
**Integrity (CRITICAL)**
Medical data integrity is literally a matter of life and death. If a patient's allergy information is tampered with, or their medication dosage is modified, or a prescription refill is altered, the result could be severe injury or death. An attacker who modifies a patient's blood type in a record before emergency surgery, or changes insulin dosage instructions, creates conditions for fatal medical errors.
 
**Availability (HIGH)**
While critical, availability ranks slightly below the other two in this context. Brief outages are inconvenient but generally manageable in non-emergency scenarios (paper backups, hospital systems). However, extended unavailability during a critical care moment could still have life-threatening consequences.
 
### Conclusion
 
**Confidentiality and Integrity are co-equal top priorities** for patient medical records. This is reinforced by HIPAA regulations, which mandate both privacy protections (confidentiality) and audit controls to detect unauthorized modifications (integrity). A breach of either has irreversible consequences — legal, financial, and potentially fatal.
 
---
 
## Question 2: STRIDE Analysis — "Message Healthcare Providers" Feature
 
### Feature Description
Patients send secure messages to doctors/nurses. Messages may contain symptoms, questions about medications, and sensitive health information. Providers respond with medical advice.
 
---
 
### Threat 1 — Spoofing (Identity Impersonation)
 
**STRIDE Category:** Spoofing
 
**Threat Description:** An attacker impersonates a healthcare provider to send fake medical advice to patients. For example, a malicious actor creates an account appearing to be "Dr. Smith" and responds to patient messages with incorrect medication instructions.
 
**Attack Scenario:**
```
Attacker registers account with name "Dr. Sarah Johnson"
→ Patients cannot distinguish fake from real provider
→ Attacker sends false medical advice: "Stop taking your blood pressure medication"
→ Patient follows advice, experiences medical emergency
```
 
**Impact:** Patient harm or death from acting on false medical advice; legal liability for the platform; HIPAA violations for failure to verify provider identity
 
**Mitigation:** Implement verified provider badges with identity verification during onboarding; use separate authentication flows for providers vs patients; display provider credentials from hospital system integration
 
---
 
### Threat 2 — Tampering (Message Modification)
 
**STRIDE Category:** Tampering
 
**Threat Description:** An attacker with access to the message transmission layer modifies messages in transit. A doctor's prescription refill approval ("Approve 10mg") is changed to ("Approve 100mg").
 
**Attack Scenario:**
```
Doctor sends message: "Approved: Metformin 500mg twice daily"
→ Attacker with MitM position intercepts message
→ Modifies dosage: "Approved: Metformin 5000mg twice daily"
→ Patient receives dangerous overdose instructions
```
 
**Impact:** Fatal medication errors; inability to detect tampering without integrity controls; legal liability
 
**Mitigation:** Implement end-to-end encryption for all messages; use digital signatures so recipients can verify message authenticity; implement TLS certificate pinning in the mobile app to prevent MitM attacks
 
---
 
### Threat 3 — Repudiation (Denial of Medical Advice Given)
 
**STRIDE Category:** Repudiation
 
**Threat Description:** A healthcare provider denies having sent a message containing medical advice, making it impossible to resolve disputes about what instructions were given to the patient.
 
**Attack Scenario:**
```
Doctor sends message: "You can stop your medication"
→ Patient follows advice, experiences adverse event
→ Doctor denies sending that message
→ No audit trail exists to verify what was sent
→ Legal dispute cannot be resolved
```
 
**Impact:** Legal liability cannot be properly assigned; regulatory non-compliance; inability to investigate adverse events; malpractice claims
 
**Mitigation:** Implement comprehensive audit logging with timestamps, user IDs, and message hashes; store immutable message logs; use digital signatures on provider messages so they cannot be repudiated; retain logs for minimum 6 years per HIPAA requirements
 
---
 
### Threat 4 — Information Disclosure (Unauthorized PHI Access)
 
**STRIDE Category:** Information Disclosure
 
**Threat Description:** A patient accesses another patient's message thread by manipulating the message ID in the API request (Insecure Direct Object Reference — IDOR).
 
**Attack Scenario:**
```
Patient A receives message at /api/messages/thread/12345
→ Patient A changes URL to /api/messages/thread/12346
→ API returns Patient B's messages with their PHI
→ Patient A reads sensitive mental health or HIV status information
```
 
**Impact:** HIPAA violation; exposure of highly sensitive PHI; $100-$50,000 fine per exposed record; reputational damage
 
**Mitigation:** Implement object-level authorization checks on every message request; never expose sequential IDs (use UUIDs); validate that the requesting user owns the resource before returning data
 
---
 
### Threat 5 — Denial of Service (Message System Overload)
 
**STRIDE Category:** Denial of Service
 
**Threat Description:** An attacker floods the messaging API with thousands of requests, making the system unavailable to genuine patients who need urgent medical communication.
 
**Attack Scenario:**
```
Attacker scripts 10,000 message send requests per minute
→ API backend becomes overwhelmed
→ Legitimate patients cannot message providers
→ Patient with urgent symptom cannot reach doctor
→ Delayed care leads to adverse medical outcome
```
 
**Impact:** Unavailability of critical medical communication; patient harm from delayed care; SLA violations; HIPAA availability requirement violations
 
**Mitigation:** Implement rate limiting per user account; use a CDN/WAF for DDoS protection; implement circuit breakers; set up autoscaling with defined resource limits
 
---
 
## Question 3: Five Priority Security Controls for Patient Data
 
### Priority 1: Multi-Factor Authentication (MFA) for All Users
 
**Why first:** Authentication is the gateway to all PHI. If an attacker can log in as a patient or provider, all other controls are bypassed. MFA is the single most effective control against credential compromise, reducing account takeover risk by over 99% according to Microsoft research.
 
**Implementation:** TOTP (Google Authenticator) or biometric authentication for mobile; mandatory for all accounts; step-up authentication required for sensitive actions (viewing records, approving prescriptions)
 
---
 
### Priority 2: End-to-End Encryption of PHI at Rest and in Transit
 
**Why second:** Even with authentication, data must be protected if infrastructure is compromised. Encryption ensures that a database breach or cloud misconfiguration does not expose readable PHI.
 
**Implementation:**
- TLS 1.3 for all API communications
- AES-256 encryption for PHI stored in the database
- Encrypted backups with separate key management (AWS KMS or HashiCorp Vault)
- Certificate pinning in mobile apps to prevent MitM attacks
---
 
### Priority 3: Role-Based Access Control (RBAC) with Minimum Necessary Access
 
**Why third:** HIPAA's "minimum necessary" standard requires that users only access PHI relevant to their role. A receptionist should not see lab results; a cardiologist should not access psychiatry notes.
 
**Implementation:**
- Define distinct roles: Patient, Nurse, Doctor, Specialist, Administrator
- Implement attribute-based access control (ABAC) for fine-grained permissions
- Patients can only access their own records
- Providers can only access records of patients under their care
- Regular access reviews every 90 days
---
 
### Priority 4: Comprehensive Audit Logging and Monitoring
 
**Why fourth:** HIPAA requires audit controls to detect unauthorized access. Logging creates the evidence trail necessary for incident response, compliance audits, and legal proceedings.
 
**Implementation:**
- Log all PHI access events: who, what, when, from where
- Immutable logs stored separately from application (cannot be modified or deleted)
- Real-time alerting on anomalous access patterns (e.g., one user accessing 500 records in an hour)
- Retain logs for minimum 6 years
- Regular log review and SIEM integration
---
 
### Priority 5: Secure API Design with Input Validation and IDOR Prevention
 
**Why fifth:** The REST API is the attack surface through which all PHI is accessed. Without proper API security, authentication and encryption can be bypassed through logic flaws.
 
**Implementation:**
- Validate all input on the server side (never trust client)
- Use UUIDs instead of sequential IDs for all resources
- Implement object-level authorization on every endpoint
- Rate limiting on all API endpoints
- Regular API security testing (OWASP API Security Top 10)
---
 
*Threat model created following STRIDE methodology and CIA Triad framework. Compliant with HIPAA Security Rule requirements.*
 

