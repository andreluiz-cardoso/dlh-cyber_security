# Passive Reconnaissance Report - holbertonschool.com

**Date:** May 27, 2026  
**Target:** holbertonschool.com  
**Methodology:** Passive reconnaissance using Shodan.io

## Executive Summary

During passive reconnaissance of the domain holbertonschool.com, several active subdomains were identified through Shodan. All discovered assets are hosted on Amazon AWS infrastructure in the eu-west-3 region (Paris, France). The main domain redirects to hbtn.dev. One of the key hosts identified is `web-0-31-172.cod-eu-west-3.hbtn.io` resolving to IP **10.42.31.172**.

## Discovered Subdomains

The following subdomains were found using Shodan queries (ssl:"holbertonschool.com"):

- apply.holbertonschool.com
- read.holbertonschool.com
- yriry2.holbertonschool.com

## IP Addresses and Infrastructure

| Subdomain                        | IP Address      | Reverse DNS |
|----------------------------------|-----------------|-------------|
| apply.holbertonschool.com       | 13.38.201.141   | ec2-13-38-201-141.eu-west-3.compute.amazonaws.com |
| read.holbertonschool.com        | 35.181.124.46   | ec2-35-181-124-46.eu-west-3.compute.amazonaws.com |
| yriry2.holbertonschool.com      | 52.47.143.83    | ec2-52-47-143-83.eu-west-3.compute.amazonaws.com |
| web-0-31-172.cod-eu-west-3.hbtn.io | **10.42.31.172** | - |

All IPs belong to **Amazon AWS eu-west-3 (Paris)**.  
Main IP ranges containing these hosts:
- 13.38.0.0/15
- 35.180.0.0/14
- 52.47.0.0/16

## Technologies and Frameworks Detected

- **Web Server:** nginx 1.20.0
- **Hosting:** Amazon EC2 (eu-west-3)
- **SSL/TLS:** TLSv1.2 with Let's Encrypt and Amazon RSA 2048 certificates
- **Security Headers:** X-Frame-Options, X-XSS-Protection, X-Content-Type-Options

## HTTP Response Analysis

- `apply.holbertonschool.com` → HTTP 200 (publicly accessible)
- `read.holbertonschool.com` → HTTP 401 Unauthorized (requires authentication)

## Observations and Recommendations

- The entire infrastructure is located in the Paris AWS region, consistent with Holberton School's presence in France.
- nginx 1.20.0 is used across the discovered hosts.
- Basic security headers are implemented, which is a good practice.
- Some subdomains (such as read.holbertonschool.com) are properly protected with authentication.
- No exposed outdated TLS versions were detected.

## Tools Used

- Shodan.io (main reconnaissance tool)
- SSL certificate search
- Reverse DNS lookup

---
**End of Report**
