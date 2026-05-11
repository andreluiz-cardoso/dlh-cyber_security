# 0x02 - Mandatory Access Control (MAC)

This directory contains Bash scripts for managing and auditing Mandatory Access Control systems on Linux, focusing on **SELinux** and **AppArmor**.

## Tasks

### 0. `0-analyse_mode.sh`
Displays the current SELinux mode (Enforcing, Permissive, or Disabled).  
*Command:* `sestatus | grep "SELinux status"`

### 1. `1-security_match.sh`
Shows the status of AppArmor security profiles (loaded profiles, modes, and processes).  
*Command:* `aa-status`

### 2. `2-list_http.sh`
Lists all SELinux ports related to HTTP services (e.g., `http_port_t`, `http_cache_port_t`).  
*Command:* `semanage port -l | grep http`

### 3. `3-add_port.sh`
Adds TCP port 81 to the SELinux `http_port_t` type, allowing web servers to bind to it.  
*Command:* `semanage port -a -t http_port_t -p tcp 81`

### 4. `4-list_user.sh`
Lists all SELinux user mappings with their roles, prefixes, and MLS/MCS levels.  
*Command:* `semanage user -l`

### 5. `5-add_selinux.sh`
Maps a system login (passed as argument) to the SELinux identity `user_u`.  
*Command:* `semanage login -a -s user_u "$1"`

### 6. `6-list_booleans.sh`
Lists all SELinux booleans (toggle‑able security settings) with descriptions.  
*Command:* `semanage boolean -l`

### 7. `7-set_sendmail.sh`
Permanently enables the SELinux boolean `httpd_can_sendmail`, allowing web servers to send emails.  
*Command:* `setsebool -P httpd_can_sendmail on`

## Usage
All scripts must be executed with **root privileges** (using `sudo`).  
Example:
```bash
sudo ./0-analyse_mode.sh
sudo ./1-security_match.sh
sudo ./2-list_http.sh
