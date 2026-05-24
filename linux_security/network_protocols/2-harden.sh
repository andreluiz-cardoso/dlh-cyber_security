#!/bin/bash
find / -xdev -type d -perm -o+w -exec chmod 755 {} \; -print 2>/dev/null
