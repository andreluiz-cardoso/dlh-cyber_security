#!/usr/bin/env python3
import dns.resolver

def query_dns_records(domain_name):
    record_types = ['A', 'AAAA', 'MX', 'NS', 'TXT', 'SOA']
    results = {}
    for rtype in record_types:
        try:
            answers = dns.resolver.resolve(domain_name, rtype)
            results[rtype] = answers
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN, dns.resolver.NoNameservers):
            continue
    return results
