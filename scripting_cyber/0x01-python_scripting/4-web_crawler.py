#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

def crawl_website(start_url, max_depth=2):
    visited = set()
    base_domain = urlparse(start_url).netloc

    def crawl(url, depth):
        if depth > max_depth or url in visited:
            return
        try:
            print(f"Crawling: {url}")
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            visited.add(url)
            soup = BeautifulSoup(response.text, 'html.parser')
            for link in soup.find_all('a', href=True):
                full_url = urljoin(url, link['href'])
                parsed = urlparse(full_url)
                if parsed.netloc == base_domain and full_url not in visited:
                    crawl(full_url, depth + 1)
        except Exception:
            pass

    crawl(start_url, 1)
    return visited
