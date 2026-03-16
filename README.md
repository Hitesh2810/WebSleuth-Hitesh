
# <b> Only DNS enumeration and subdomain discovery is functional for now </b>
# WebSleuth 🚀🌐
**The Ultimate Website Reconnaissance Tool** 🕵️‍♂️💻

Welcome to **WebSleuth**! This is your one-stop reconnaissance tool for gathering crucial information about websites. Whether you're a cybersecurity professional, a pen tester, or just a curious soul, **WebSleuth** has you covered with its super cool and comprehensive modules.

---

## 🎯 Features:
- 🔍 **DNS Enumeration** – Dig deep into DNS records like A, AAAA, MX, and TXT
- 🌐 **Subdomain Discovery** – Find all hidden subdomains with brute force using custom wordlists
- 🗂 **Directory Discovery** – Uncover hidden directories and files
- 🛠 **Technology Stack Identification** – Reveal the tech stack behind the target site
- 🔑 **SSL/TLS Analysis** – Check for SSL vulnerabilities and security configurations
- 📜 **WHOIS Lookup** – Find out everything about the domain’s registration
- 📝 **HTTP Headers Analysis** – Peek into HTTP response headers for hidden info
- ⚡ **Port Scanning** – Scan open ports and gather valuable data
- 🧩 **Modular & Customizable** – Choose and run only the modules you need

---

## 🛠 Installation
To install **WebSleuth**, follow these steps:

1. Clone the repo:
    ```bash
    git clone https://github.com/cyb3ritic/WebSleuth.git
    cd WebSleuth
    ```
2. Make sure you have all required tools installed:
    ```bash
    sudo apt-get install dig curl nmap whois openssl whatweb
    ```

3. Give execute permission to the script:
    ```bash
    chmod +x websleuth.sh
    ```

4. Run the script:
    ```bash
    sudo ./websleuth.sh -u <target-url> [options]
    ```

---

## 🧑‍💻 Usage
Ready to go? Here’s how to use **WebSleuth**! 🎉

### Basic Usage:
```bash
sudo ./websleuth.sh -u <target-url> [options]
