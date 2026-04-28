#!/bin/bash

# Smartsheet MCP Setup Script
# Configures Smartsheet MCP using Claude Code's built-in MCP management

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "Smartsheet MCP Setup"
echo "===================="

# Check if Claude Code is available
if ! command -v claude > /dev/null; then
    echo -e "${RED}Error: Claude Code CLI not found${NC}"
    echo "Please install Claude Code first: https://claude.ai/code"
    exit 1
fi

# Check for existing MCP configuration
MCP_CONFIG_PATH="$HOME/.claude.json"
if [[ -f "$MCP_CONFIG_PATH" ]]; then
    echo -e "${YELLOW}Existing MCP configuration found at:${NC}"
    echo -e "${BLUE}$MCP_CONFIG_PATH${NC}"
    echo

    # Check if smartsheet-mcp already exists
    if claude mcp list 2>/dev/null | grep -q "smartsheet-mcp"; then
        echo -e "${YELLOW}Warning: smartsheet-mcp is already configured.${NC}"
        echo "Proceeding will override the existing configuration."
        echo
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled."
            exit 0
        fi
        echo
        echo "Removing existing smartsheet-mcp configuration..."
        if ! claude mcp remove smartsheet-mcp; then
            echo -e "${RED}Error: Failed to remove existing configuration${NC}"
            exit 1
        fi
        echo -e "${GREEN}Existing configuration removed.${NC}"
        echo
    fi
else
    echo "No existing MCP configuration found."
    echo -e "Configuration will be created at: ${BLUE}$MCP_CONFIG_PATH${NC}"
    echo
fi

# Prompt for API token
echo "Please enter your Smartsheet API token:"
echo "(You can get this from Account > Personal Settings > API Access in Smartsheet)"
echo -n "Token: "

# Read token with input masking
read -s API_TOKEN
echo  # New line after masked input

# Basic validation
if [[ -z "$API_TOKEN" ]]; then
    echo -e "${RED}Error: No token provided${NC}"
    exit 1
fi

if [[ ${#API_TOKEN} -lt 10 ]]; then
    echo -e "${RED}Error: Token seems too short (${#API_TOKEN} characters)${NC}"
    exit 1
fi

echo
echo "Token received (${#API_TOKEN} characters)"
echo

# Add MCP configuration using Claude Code CLI
echo "Configuring Smartsheet MCP..."
if claude mcp add --transport http smartsheet-mcp \
    https://mcp.smartsheet.com \
    -H "Authorization:Bearer ${API_TOKEN}"; then

    echo
    echo -e "${GREEN}Setup complete!${NC}"
    echo
    echo "Configuration details:"
    echo -e "  • MCP Name: ${BLUE}smartsheet-mcp${NC}"
    echo -e "  • Endpoint: ${BLUE}https://mcp.smartsheet.com${NC}"
    echo -e "  • Config Path: ${BLUE}$MCP_CONFIG_PATH${NC}"
    echo
    echo "Next steps:"
    echo "1. Restart your Claude Code session if it's running"
    echo "2. Test the connection by asking: 'Who's the bottleneck across my active projects?'"
    echo "3. View all MCPs with: claude mcp list"

else
    echo
    echo -e "${RED}Error: Failed to configure MCP${NC}"
    echo "Please check your API token and try again."
    exit 1
fi