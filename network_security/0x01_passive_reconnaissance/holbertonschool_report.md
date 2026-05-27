# Passive Reconnaissance Report - holbertonschool.com

**Date:** May 27, 2026  
**Tools used:** Shodan.io, DNS enumeration (dig, nslookup, subfinder)

## 1. IP Ranges and Hosts Discovered

Using Shodan searches with the operator `hostname:holbertonschool.com` and DNS records:

- **Main IP Addresses:**
  - 75.2.70.75
  - 99.83.190.102

- **Organization:** Amazon.com, Inc. (AWS Global Accelerator)
- **ASN:** AS16509
- **Location:** United States / Seattle
- **Network Technology:** AWS Global Accelerator + CloudFront CDN

**Note:** All subdomains resolve to these two IP addresses. Shodan shows limited additional hosts because the domain is protected behind AWS infrastructure.

## 2. Subdomains Discovered

Full list of subdomains found via Subfinder (saved in `holbertonschool.com.txt`):

- www.holbertonschool.com
- apply.holbertonschool.com
- blog.holbertonschool.com
- support.holbertonschool.com
- fr.holbertonschool.com
- assets.holbertonschool.com
- webflow.holbertonschool.com
- v1.holbertonschool.com, v2.holbertonschool.com, v3.holbertonschool.com
- staging-*.holbertonschool.com (multiple staging environments)
- beta.holbertonschool.com, alpha.holbertonschool.com
- rails-assets.holbertonschool.com
- help.holbertonschool.com
- and 15+ additional subdomains

All subdomains point to the same two AWS IP addresses.

## 3. Technologies and Frameworks Detected

**Web Server / Proxy:**
- Nginx (detected via Shodan on both IPs)

**Cloud / Infrastructure:**
- Amazon Web Services (AWS)
- AWS Global Accelerator
- CloudFront (CDN)

**Confirmed via DNS TXT Records:**
- Google Workspace (SPF + MX)
- Microsoft 365 (`MS=BB8A869E...`)
- Apple domain verification
- Dropbox domain verification
- Zendesk
- Mailgun
- Intacct
- Loader.io (load testing)

**Frameworks / Platforms:**
- Webflow (multiple subdomains)
- Ruby on Rails (`rails-assets.holbertonschool.com`)
- Discourse (forum platform)
- Google services (site verification)

**Open Ports (Shodan):**
- Port 80 (HTTP) → Nginx + redirect to HTTPS
- Port 443 (HTTPS) → Protected by CloudFront

## 4. Conclusions and Security Observations

- The domain uses highly optimized AWS infrastructure (Global Accelerator + CDN), making full mapping difficult.
- Multiple public staging and development subdomains increase the attack surface.
- Heavy use of third-party services (Google, Microsoft, Zendesk, etc.).
- Recommendation: Monitor staging subdomains and apply strict hardening on Nginx/CloudFront.

**Sources:**
- Shodan.io (hostname and IP searches)
- DNS enumeration (dig, nslookup, subfinder)
- Public records (WHOIS, DNS TXT/MX/NS)

---
**End of Report**
