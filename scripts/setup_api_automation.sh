#!/bin/bash

# Setup and run App Store Connect API automation

set -e

echo "🔧 Setting up App Store Connect API Automation"
echo "==============================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    exit 1
fi

echo "${GREEN}✅ Python 3 found${NC}"

# Install dependencies
echo ""
echo "${YELLOW}📦 Installing Python dependencies...${NC}"

# Try pip3, then python3 -m pip if pip3 fails
if ! python3 -m pip install --quiet --user pyjwt requests cryptography pillow 2>/dev/null; then
    echo "${YELLOW}⚠️  Installing with alternative method...${NC}"
    python3 -m ensurepip --default-pip 2>/dev/null || true
    python3 -m pip install --user pyjwt requests cryptography pillow
fi

echo "${GREEN}✅ Dependencies installed${NC}"

# Run API script
echo ""
echo "${BLUE}🚀 Running complete App Store submission automation...${NC}"
echo ""

python3 "./scripts/complete_appstore_submission.py"

echo ""
echo "${GREEN}✅ API automation complete!${NC}"

