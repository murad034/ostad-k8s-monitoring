#!/bin/bash

# VPN Setup Script for Dhaka Colo-3
# This script configures and connects to the PPTP VPN

set -e

echo "========================================="
echo "VPN Setup - Dhaka Colo-3"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VPN_HOST="103.143.148.217"
VPN_USER="murad"
VPN_PASS='Md5$b$yT6myUsT'
VPN_NAME="dhakacolo3"

# Check if PPTP is installed
echo -e "${YELLOW}Step 1: Check PPTP client${NC}"
if ! command -v pptp &> /dev/null; then
    echo "Installing PPTP client..."
    sudo apt update
    sudo apt install -y pptp-linux ppp
else
    echo -e "${GREEN}✓ PPTP client already installed${NC}"
fi

# Create VPN peer configuration
echo -e "${YELLOW}Step 2: Configure VPN peer${NC}"
sudo tee /etc/ppp/peers/${VPN_NAME} > /dev/null <<EOF
pty "pptp ${VPN_HOST} --nolaunchpppd"
name ${VPN_USER}
remotename ${VPN_NAME}
require-mppe-128
file /etc/ppp/options.pptp
ipparam ${VPN_NAME}
defaultroute
replacedefaultroute
usepeerdns
EOF
echo -e "${GREEN}✓ Peer configuration created${NC}"

# Create credentials file
echo -e "${YELLOW}Step 3: Configure credentials${NC}"
# Use printf to avoid issues with special characters
sudo bash -c "cat > /etc/ppp/chap-secrets" <<'EOF'
# Secrets for authentication using CHAP
# client        server  secret                  IP addresses
murad     dhakacolo3     "Md5$b$yT6myUsT"     *
murad     *              "Md5$b$yT6myUsT"     *
EOF
sudo chmod 600 /etc/ppp/chap-secrets
echo -e "${GREEN}✓ Credentials configured${NC}"

# Configure PPP options
echo -e "${YELLOW}Step 4: Configure PPP options${NC}"
sudo tee /etc/ppp/options.pptp > /dev/null <<EOF
lock
noauth
nobsdcomp
nodeflate
refuse-eap
refuse-pap
refuse-chap
require-mschap-v2
require-mppe-128
EOF
echo -e "${GREEN}✓ PPP options configured${NC}"

# Stop any existing connection
echo -e "${YELLOW}Step 5: Stop existing VPN connections${NC}"
sudo poff -a 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Existing connections stopped${NC}"

# Connect to VPN
echo -e "${YELLOW}Step 6: Connect to VPN${NC}"
echo "Connecting to ${VPN_HOST}..."
sudo pon ${VPN_NAME} updetach

# Wait for connection
echo "Waiting for VPN connection..."
for i in {1..10}; do
    if ip addr show ppp0 &>/dev/null; then
        echo -e "${GREEN}✓ VPN connected!${NC}"
        break
    fi
    echo "Waiting... ($i/10)"
    sleep 2
done

# Verify connection
echo -e "${YELLOW}Step 7: Verify connection${NC}"
if ip addr show ppp0 &>/dev/null; then
    echo ""
    echo "VPN Interface:"
    ip addr show ppp0
    echo ""
    echo "VPN Routes:"
    ip route | grep ppp0 || echo "No specific ppp0 routes"
    echo ""
    
    # Test database connectivity
    echo -e "${YELLOW}Step 8: Test database connectivity${NC}"
    echo "Testing connection to 10.10.200.60:30333..."
    
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/10.10.200.60/30333" 2>/dev/null; then
        echo -e "${GREEN}✓ Database is reachable!${NC}"
    else
        echo -e "${YELLOW}⚠ Database not reachable yet. This might be normal if routing needs time.${NC}"
        echo "Trying ping..."
        ping -c 3 10.10.200.60 || echo "Ping failed, but VPN is connected."
    fi
    
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✓ VPN Setup Complete!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "VPN Status:"
    echo "  Connection: Connected"
    echo "  Server: ${VPN_HOST}"
    echo "  Interface: ppp0"
    echo ""
    echo "Useful Commands:"
    echo "  Check status: ip addr show ppp0"
    echo "  Check routes: ip route | grep ppp0"
    echo "  View logs: sudo tail -f /var/log/syslog | grep ppp"
    echo "  Disconnect: sudo poff ${VPN_NAME}"
    echo "  Reconnect: sudo pon ${VPN_NAME}"
    echo ""
    echo "Next Steps:"
    echo "  1. Test database: nc -zv 10.10.200.60 30333"
    echo "  2. Deploy backend: ./scripts/deploy-esim-no-changes.sh"
    echo ""
else
    echo -e "${RED}✗ VPN connection failed${NC}"
    echo ""
    echo "Checking logs..."
    sudo tail -30 /var/log/syslog | grep -E "pptp|ppp" || echo "No logs found"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check credentials in /etc/ppp/chap-secrets"
    echo "  2. View full logs: sudo tail -100 /var/log/syslog | grep -E 'pptp|ppp'"
    echo "  3. Try manual connection: sudo pon ${VPN_NAME} debug dump logfd 2 nodetach"
    exit 1
fi
