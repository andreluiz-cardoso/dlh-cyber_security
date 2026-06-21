# Threat Model: IoT Smart Thermostat
 
## System Overview
 
A smart thermostat that connects to home Wi-Fi, controls heating/cooling systems (HVAC), collects temperature data, receives commands from a mobile app, and supports over-the-air (OTA) firmware updates.
 
---
 
## Question 1: IoT-Specific Threats
 
The following threats are specific to IoT devices and do not typically apply to traditional web applications:
 
---
 
### Threat 1: Physical Tampering and Hardware Exploitation
 
**Description:** An attacker with physical access to the thermostat can open the device and access debug interfaces (JTAG, UART serial ports) that are often left enabled in production firmware. These ports provide direct access to the device's operating system with root privileges.
 
**Why IoT-specific:** Web applications run on secured server infrastructure with physical access controls. IoT devices sit in homes, offices, and public spaces where physical access cannot be controlled.
 
**Attack:** Attacker connects a USB-to-serial adapter to the UART port on the PCB, boots into a root shell, and extracts the entire filesystem including Wi-Fi credentials, API keys, and encryption keys stored in plaintext.
 
**Mitigation:** Disable debug interfaces in production firmware; implement secure boot to prevent unauthorized firmware; use hardware security modules (HSM) for key storage; epoxy over debug ports
 
---
 
### Threat 2: Default or Hardcoded Credentials
 
**Description:** Many IoT devices ship with default credentials (admin/admin, root/root) or hardcoded credentials embedded in firmware that cannot be changed. Attackers scan the internet for devices using these known credentials.
 
**Why IoT-specific:** Web applications enforce password policies and require unique credentials during account creation. IoT devices are often deployed by non-technical users who never change defaults.
 
**Attack:** Attacker uses Shodan to find thermostats with exposed management interfaces, tries default credentials, gains control of thousands of devices simultaneously, enrolls them in a botnet (similar to Mirai botnet which compromised 600,000 IoT devices in 2016).
 
**Mitigation:** Force unique password creation during device setup; never ship with hardcoded credentials; implement credential hashing; lock out accounts after failed attempts
 
---
 
### Threat 3: Unencrypted Local Network Communications
 
**Description:** The thermostat communicates with the mobile app and cloud backend over the local Wi-Fi network using unencrypted protocols (plain HTTP, MQTT without TLS). Any device on the same network can intercept commands and data.
 
**Why IoT-specific:** Modern web browsers enforce HTTPS. IoT devices frequently use lightweight protocols without encryption due to processing constraints.
 
**Attack:** Guest on the home Wi-Fi network runs Wireshark, captures all thermostat traffic, intercepts temperature commands and API tokens, replays commands to control the HVAC system, or extracts API keys to access the cloud account.
 
**Mitigation:** Use TLS for all communications (MQTT over TLS = MQTTS); implement certificate validation; use mutual TLS (mTLS) for device authentication; never use plain HTTP
 
---
 
### Threat 4: Insecure Over-The-Air (OTA) Firmware Updates
 
**Description:** The device accepts firmware updates over the network without properly verifying the update's authenticity or integrity. An attacker can push malicious firmware that turns the device into a backdoor or destroys it.
 
**Why IoT-specific:** Web applications update server-side code in controlled environments. IoT devices update autonomously in the field with potentially limited connectivity and no human oversight.
 
**Attack:** Attacker performs a MitM attack on the firmware update channel, replaces legitimate firmware with malicious version that exfiltrates Wi-Fi credentials, opens a reverse shell, or physically damages the HVAC system by sending extreme temperature commands.
 
**Mitigation:** Cryptographically sign all firmware with a private key; device verifies signature before installation; use secure boot to verify signature at boot time; implement rollback protection to prevent downgrade attacks
 
---
 
### Threat 5: Side-Channel Attacks and Behavioral Analysis
 
**Description:** By monitoring the thermostat's data (temperature readings, when heating/cooling activates, energy usage patterns), an attacker can determine when occupants are home, their daily schedules, and when the property is vacant.
 
**Why IoT-specific:** This threat is unique to physical-world sensing devices. A web application doesn't collect data about physical presence in a location.
 
**Attack:** Attacker who gains access to the thermostat's cloud account (through credential stuffing or phishing) analyzes 6 months of temperature and occupancy data to determine the homeowner's work schedule, vacation dates, and times the house is empty — enabling targeted burglary.
 
**Mitigation:** Aggregate and anonymize usage data before cloud storage; implement strict access controls on historical data; provide data retention limits; add data access notifications
 
---
 
### Threat 6: Zigbee/Z-Wave Protocol Exploitation
 
**Description:** If the thermostat uses home automation protocols (Zigbee, Z-Wave, Bluetooth), these protocols have known vulnerabilities including weak pairing mechanisms, replay attacks, and protocol-level denial of service.
 
**Why IoT-specific:** These protocols are specific to IoT/home automation ecosystems and don't exist in web application environments.
 
**Attack:** Attacker within radio range uses a software-defined radio (SDR) to capture and replay Zigbee commands, spoofs the mobile app to send unauthorized temperature commands, or jams the frequency to prevent legitimate control.
 
**Mitigation:** Use latest protocol versions with encryption enabled; implement message replay protection (sequence numbers, timestamps); validate command sources
 
---
 
## Question 2: Physical Access Attack Chain
 
### Attacker Gains Physical Access to the Device
 
**Assumed attacker:** A malicious house guest, contractor, or burglar with 15-30 minutes of physical access to the thermostat.
 
---
 
### Attack Chain
 
**Step 1: Device Removal**
```
Attacker removes thermostat from wall mount (takes ~30 seconds)
→ Device powered by wall wiring or battery backup
→ Attacker has access to the physical PCB
```
 
**Step 2: Debug Interface Discovery**
```
Attacker examines PCB for JTAG/UART test points
→ Uses multimeter to identify UART TX/RX/GND pins
→ Connects USB-to-serial adapter (cost: $5)
→ Opens serial terminal at common baud rates (115200)
→ Boots into root Linux shell (if debug interface not disabled)
```
 
**Step 3: Filesystem Extraction**
```
From root shell, attacker runs: cat /etc/config
→ Extracts Wi-Fi SSID and password (stored in plaintext)
→ Extracts cloud API keys and device authentication tokens
→ Copies /etc/shadow for offline password cracking
→ Finds hardcoded backend API endpoints
```
 
**Step 4: Firmware Extraction and Analysis**
```
Attacker runs: dd if=/dev/mtd0 of=/tmp/firmware.bin
→ Extracts full firmware image via serial connection
→ Analyzes with Binwalk to decompress filesystem
→ Reverse engineers application code with Ghidra
→ Discovers additional hardcoded credentials and API keys
→ Finds encryption keys stored in firmware
```
 
**Step 5: Persistent Backdoor Installation**
```
Attacker modifies firmware to add persistent backdoor:
→ Adds SSH server with attacker's public key
→ Installs reverse shell that calls home on boot
→ Disables firmware signature verification
→ Reinstalls thermostat on wall
→ Device appears completely normal to homeowner
```
 
**Step 6: Lateral Movement**
```
With Wi-Fi credentials extracted in Step 3:
→ Attacker connects to home network remotely (if router accessible)
→ Scans internal network for other devices
→ Attacks NAS drives, security cameras, computers
→ Pivots to corporate VPN if homeowner uses remote work setup
→ Achieves complete home network compromise
```
 
### Potential Impacts
 
- **Immediate:** Complete control of home HVAC — attacker can set temperature to dangerous extremes (e.g., 5°C in winter, 45°C in summer) causing property damage or health risks
- **Short-term:** Wi-Fi credential theft enables access to all devices on the home network
- **Long-term:** Persistent backdoor survives factory reset if firmware is compromised; attacker maintains permanent access
- **Cascading:** Corporate network breach if homeowner uses VPN; access to other smart home devices (locks, cameras, alarm systems)
---
 
## Question 3: Security Controls for OTA Update Process
 
### Essential Security Requirements for OTA Updates
 
---
 
### Requirement 1: Cryptographic Code Signing
 
**Description:** Every firmware image must be cryptographically signed using asymmetric cryptography before distribution. The device must verify the signature before executing any update.
 
**Implementation:**
```
Vendor generates RSA-4096 or ECDSA P-256 key pair
→ Private key stored in Hardware Security Module (HSM) — never extracted
→ Firmware signed during build process: signature = sign(SHA-256(firmware), private_key)
→ Signature distributed alongside firmware image
→ Device verifies: verify(signature, SHA-256(downloaded_firmware), public_key)
→ Update rejected if signature verification fails
```
 
**Why essential:** Prevents installation of malicious firmware even if the update distribution channel is compromised.
 
---
 
### Requirement 2: Secure Boot Chain
 
**Description:** The device must verify the integrity and authenticity of software at every boot stage, from bootloader to application firmware.
 
**Implementation:**
```
Stage 1: ROM bootloader (immutable, burned into silicon)
  → Verifies Stage 2 bootloader signature
Stage 2: Signed bootloader
  → Verifies OS kernel signature
Stage 3: Signed OS kernel
  → Verifies application firmware signature
Stage 4: Application
  → Verifies update packages before applying
```
 
**Why essential:** Ensures that even if malicious firmware is written to flash memory (via physical attack), the device will not execute it without a valid signature.
 
---
 
### Requirement 3: Encrypted Update Channel (TLS 1.3)
 
**Description:** All firmware downloads must occur over encrypted connections with proper certificate validation. The device must validate the server's TLS certificate to prevent MitM attacks.
 
**Implementation:**
- Use TLS 1.3 for all update server connections
- Implement certificate pinning — device only trusts the vendor's specific certificate, not the entire CA chain
- Validate certificate Common Name matches expected update server hostname
- Reject updates from any server not matching the pinned certificate
**Why essential:** Prevents network-level interception and replacement of firmware during download, even on compromised networks.
 
---
 
### Requirement 4: Rollback Protection
 
**Description:** The device must maintain a record of the minimum acceptable firmware version and refuse to install older versions, preventing downgrade attacks that would re-expose patched vulnerabilities.
 
**Implementation:**
```
Firmware header includes: version number, security version number (SVN)
Device stores: minimum acceptable SVN in write-protected storage
Update process checks: new_SVN >= minimum_SVN
If downgrade attempted: update rejected with error log
Minimum SVN can only be increased, never decreased
```
 
**Why essential:** An attacker who finds a vulnerability in an old firmware version cannot force a device to downgrade to the vulnerable version after a patch is released.
 
---
 
### Requirement 5: Atomic Update with Verified Boot
 
**Description:** Updates must be applied atomically using an A/B partition scheme. The new firmware is written to an inactive partition, verified, and only activated after successful verification. If activation fails, the device automatically reverts to the known-good partition.
 
**Implementation:**
```
Device maintains two firmware partitions: A (active) and B (inactive)
→ Download and write new firmware to partition B
→ Verify firmware integrity on partition B before activating
→ Set boot flag to partition B
→ Reboot and test
→ If boot fails 3 times: automatically revert to partition A
→ On success: partition A becomes new "fallback"
```
 
**Why essential:** Prevents devices from being bricked by corrupted or failed updates. A failed OTA update never leaves the device in an unbootable state.
 
---
 
### Requirement 6: Update Authorization and Authenticity Verification
 
**Description:** Devices must only accept updates from authorized update servers, and should verify that the update is intended for their specific device model and hardware version.
 
**Implementation:**
- Updates include target device model ID and hardware revision
- Device verifies update is intended for its specific model before applying
- Update server authenticates device identity before serving updates (mutual TLS or device certificates)
- Rate limiting on update checks to prevent enumeration attacks
**Why essential:** Prevents firmware designed for one device model from being flashed onto an incompatible device, which could cause hardware damage or security bypass.
 
---
 
*Threat model created following IoT Security Foundation best practices and OWASP IoT Attack Surface Areas.*

