#!/bin/bash

# WebSleuth- Advanced Website Reconnaissance Tool
# Description: Comprehensive website reconnaissance with enhanced features and user-friendly output

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[1;31m[ERROR] Please run this script as root\033[0m"
    exit 1
fi

# Required tools check
REQUIRED_TOOLS=("dig" "curl" "nmap" "whois" "openssl" "whatweb")

function check_requirements() {
    local missing_tools=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}[ERROR] Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Please install them using: sudo apt-get install ${missing_tools[*]}${NC}"
        exit 1
    fi
}

# Enhanced color palette
BOLD="\e[1m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
NC="\e[0m"

# Global variables
TARGET=""
OUTPUT=""
WORDLIST=""
THREADS=10
TIMEOUT=10
DEBUG=false
DEFAULT_WORDLIST="/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
EXCLUDED_PORTS=""
RUN_ALL=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Progress bar function
function show_progress() {
    local duration=$1
    local prefix=$2
    local width=50
    local fill="█"
    local empty="░"
    
    for ((i = 0; i <= width; i++)); do
        local percentage=$((i * 100 / width))
        local filled=$((i * width / width))
        local empty=$((width - filled))
        printf "\r${prefix} [${GREEN}%${filled}s${NC}${RED}%${empty}s${NC}] ${WHITE}${percentage}%%${NC}" "" "" 
        sleep "$duration"
    done
    echo
}

# Result formatting function
function format_result() {
    local type=$1
    local message=$2
    local timestamp=$(date "+%H:%M:%S")
    
    case $type in
        "INFO")    echo -e "${BLUE}[${timestamp}] ℹ ${NC}${message}";;
        "SUCCESS") echo -e "${GREEN}[${timestamp}] ✓ ${NC}${message}";;
        "WARNING") echo -e "${YELLOW}[${timestamp}] ⚠ ${NC}${message}";;
        "ERROR")   echo -e "${RED}[${timestamp}] ✗ ${NC}${message}";;
        "HEADER")  echo -e "${MAGENTA}${BOLD}[${timestamp}] ➤ ${NC}${BOLD}${message}${NC}";;
    esac
}

# Enhanced banner
function banner() {
    clear
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${CYAN}${BOLD}"
    echo "════════════════════════════════════════════"
    echo "           WebSleuth             "
    echo "     Advanced Website Reconnaissance Tool    "
    echo "════════════════════════════════════════════"
    echo -e "${WHITE}Started at: ${timestamp}${NC}\n"
}

# Help menu
function help_menu() {
    echo -e "${BLUE}${BOLD}WebSleuth- Advanced Usage Guide${NC}\n"
    echo -e "${WHITE}${BOLD}Basic Usage:${NC}"
    echo "  ./websleuth.sh -u <URL> [OPTIONS]"
    
    echo -e "\n${WHITE}${BOLD}Essential Options:${NC}"
    echo -e "  ${GREEN}-u, --url${NC} <URL>          Target URL for reconnaissance"
    echo -e "  ${GREEN}-o, --output${NC} <FILE>      Save output to a file (Default: results_<domain>_<timestamp>.txt)"
    echo -e "  ${GREEN}-w, --wordlist${NC} <FILE>    Custom wordlist for brute-forcing"
    echo -e "  ${GREEN}-t, --threads${NC} <NUMBER>   Number of threads (Default: 10)"
    echo -e "  ${GREEN}-a, --all${NC}                Run all reconnaissance modules"
    
    echo -e "\n${WHITE}${BOLD}Scan Modules:${NC}"
    echo -e "  ${CYAN}--dns${NC}                   DNS enumeration"
    echo -e "  ${CYAN}--subdomains${NC}            Subdomain enumeration"
    echo -e "  ${CYAN}--dirs${NC}                  Directory discovery"
    echo -e "  ${CYAN}--headers${NC}               HTTP headers analysis"
    echo -e "  ${CYAN}--ports${NC}                 Port scanning"
    echo -e "  ${CYAN}--ssl${NC}                   SSL/TLS analysis"
    echo -e "  ${CYAN}--whois${NC}                 WHOIS lookup"
    echo -e "  ${CYAN}--tech-stack${NC}            Technology stack identification"
    
    echo -e "\n${WHITE}${BOLD}Additional Options:${NC}"
    echo -e "  ${YELLOW}--timeout${NC} <SECONDS>     Set custom timeout (Default: 10)"
    echo -e "  ${YELLOW}--exclude${NC} <PORTS>       Exclude specific ports"
    echo -e "  ${YELLOW}--debug${NC}                 Enable debug mode"
    
    exit 0
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -u|--url)
      TARGET="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT="$2"
      shift 2
      ;;
    -w|--wordlist)
      WORDLIST="$2"
      shift 2
      ;;
    -t|--threads)
      THREADS="$2"
      shift 2
      ;;
    -a|--all)
      RUN_ALL=true
      shift
      ;;
    -h|--help)
      banner
      help_menu
      ;;
    --dns)
      DNS_ENUM=true
      shift
      ;;
    --subdomains)
      SUBDOMAIN_ENUM=true
      shift
      ;;
    --dirs)
      DIR_ENUM=true
      shift
      ;;
    --headers)
      HEADERS_INSPECT=true
      shift
      ;;
    --ports)
      PORT_SCAN=true
      shift
      ;;
    --ssl)
      SSL_CHECK=true
      shift
      ;;
    --whois)
      WHOIS_LOOKUP=true
      shift
      ;;
    --tech-stack)
      TECH_STACK=true
      shift
      ;;
    *)
      echo -e "${RED}[ERROR] Unknown option: $1${NC}"
      help_menu
      ;;
  esac
done

# Output handling function
function output_result() {
    local message=$1
    if [ -n "$OUTPUT" ]; then
        echo -e "$message" | tee -a "$OUTPUT"
    else
        echo -e "$message"
    fi

    if $DEBUG; then
        echo -e "${YELLOW}[DEBUG] ${message}${NC}"
    fi
}

# DNS Enumeration module
function dns_enum() {
    format_result "HEADER" "DNS Enumeration Module"
    show_progress 0.02 "Initializing DNS lookup"

    printf "${WHITE}${BOLD}%-15s %-40s %-20s${NC}\n" "Record Type" "Value" "TTL"
    echo "═════════════════════════════════════════════════════════════════════════"

    local record_types=("A" "AAAA" "MX" "TXT" "NS" "CNAME" "SOA")
    for type in "${record_types[@]}"; do
        local records=$(dig +noall +answer "$TARGET" "$type" 2>/dev/null)
        if [ -n "$records" ]; then
            while read -r record; do
                local value=$(echo "$record" | awk '{print $(NF)}')
                local ttl=$(echo "$record" | awk '{print $2}')
                printf "${CYAN}%-15s${NC} %-40s %-20s\n" "$type" "$value" "$ttl"
            done <<<"$records"
        fi
    done

    format_result "SUCCESS" "DNS Enumeration completed"
}

# Subdomain enumeration module
function subdomain_enum() {
    DEFAULT_WORDLIST="/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
    if [ -z "$WORDLIST" ]; then
        local wordlist="$DEFAULT_WORDLIST"
    else
        local wordlist="$WORDLIST"
    fi

    local target="$TARGET"

    # Check if wordlist exists
    if [[ ! -f "$wordlist" ]]; then
        format_result "ERROR" "Wordlist not found: $wordlist"
        return 1
    fi

    show_progress 0.02 "Starting subdomain enumeration"

    echo -e "\n${WHITE}${BOLD}Found Subdomains:${NC}"
    echo "════════════════════════════════════"

    # Use a faster method for checking DNS resolution
    while IFS= read -r subdomain; do
        local domain="${subdomain}.${target}"

        # Use `dig` with `+short` for faster IP resolution
        ip=$(dig +short "$domain" 2>/dev/null)

        # Only display if a valid IP is found
        if [[ -n "$ip" ]]; then
            printf "${GREEN}%-40s${NC} → ${CYAN}%s${NC}\n" "$domain" "$ip"
        fi
    done <"$wordlist"

    format_result "SUCCESS" "Subdomain enumeration completed"
}

# Directory Enumeration module
function dir_enum() {
    format_result "HEADER" "Directory Enumeration Module"

    if [ ! -f "$WORDLIST" ]; then
        format_result "ERROR" "Wordlist not found: $WORDLIST"
        return
    fi

    show_progress 0.02 "Starting directory enumeration"

    echo -e "\n${WHITE}${BOLD}Found Directories:${NC}"
    echo "════════════════════════════════════"

    while read -r path; do
        local url="http://$TARGET/$path"
        local response=$(curl -s -w "%{http_code}" -o /dev/null --max-time "$TIMEOUT" "$url")

        case $response in
        200) printf "${GREEN}%-40s${NC} → ${WHITE}Found${NC}\n" "$url" ;;
        403) printf "${YELLOW}%-40s${NC} → ${WHITE}Forbidden${NC}\n" "$url" ;;
        301 | 302) printf "${CYAN}%-40s${NC} → ${WHITE}Redirect${NC}\n" "$url" ;;
        esac
    done < <(cat "$WORDLIST" | head -n 1000) # Limit for testing, remove limit in production

    format_result "SUCCESS" "Directory enumeration completed"
}

# HTTP Headers Analysis module
function headers_analysis() {
    format_result "HEADER" "HTTP Headers Analysis Module"

    show_progress 0.02 "Retrieving HTTP headers"

    local headers=$(curl -sI "http://$TARGET" --max-time "$TIMEOUT")

    echo -e "\n${WHITE}${BOLD}HTTP Headers:${NC}"
    echo "════════════════════════════════════"
    echo "$headers"

    format_result "SUCCESS" "HTTP Headers analysis completed"
}

# Port Scanning module
function port_scan() {
    format_result "HEADER" "Port Scanning Module"

    show_progress 0.02 "Scanning ports"

    echo -e "\n${WHITE}${BOLD}Open Ports:${NC}"
    echo "════════════════════════════════════"

    nmap -p- --open "$TARGET"

    format_result "SUCCESS" "Port scanning completed"
}

# SSL/TLS Analysis module
function ssl_analysis() {
    format_result "HEADER" "SSL/TLS Analysis Module"

    show_progress 0.02 "Analyzing SSL/TLS"

    openssl s_client -connect "$TARGET:443" -showcerts </dev/null

    format_result "SUCCESS" "SSL/TLS analysis completed"
}

# WHOIS Lookup module
function whois_lookup() {
    format_result "HEADER" "WHOIS Lookup Module"

    show_progress 0.02 "Performing WHOIS lookup"

    whois "$TARGET"

    format_result "SUCCESS" "WHOIS lookup completed"
}

# Technology Stack Identification module
function tech_stack() {
    format_result "HEADER" "Technology Stack Identification Module"

    show_progress 0.02 "Identifying technology stack"

    whatweb "$TARGET"

    format_result "SUCCESS" "Technology stack identification completed"
}


# Running the script
check_requirements
banner
# Run all modules if -a/--all is specified
if $RUN_ALL; then
  DNS_ENUM=true
  SUBDOMAIN_ENUM=true
  DIR_ENUM=true
  HEADERS_INSPECT=true
  PORT_SCAN=true
  SSL_CHECK=true
  WHOIS_LOOKUP=true
  TECH_STACK=true
fi

# Execute selected modules
[ "$DNS_ENUM" == true ] && dns_enum
[ "$SUBDOMAIN_ENUM" == true ] && subdomain_enum
[ "$DIR_ENUM" == true ] && dir_enum
[ "$HEADERS_INSPECT" == true ] && headers_inspect
[ "$PORT_SCAN" == true ] && port_scan
[ "$SSL_CHECK" == true ] && ssl_check
[ "$WHOIS_LOOKUP" == true ] && whois_lookup
[ "$TECH_STACK" == true ] && tech_stack

output_result "\n${GREEN}[SUCCESS] WebReconX completed all selected modules.${NC}"
