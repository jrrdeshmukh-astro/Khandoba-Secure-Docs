#!/bin/bash

# Manage Subscriptions via App Store Connect API
# Creates/updates subscription products in App Store Connect

set -e

echo "🔐 SUBSCRIPTION PRODUCT MANAGER"
echo "================================"
echo ""

# Configuration
KEY_ID="PR62QK662L"
ISSUER_ID="69a6de99-66bd-47e3-e053-5b8c7c11a4d1"
KEY_FILE="../AuthKey_PR62QK662L.p8"
APP_ID="6738754809"  # Khandoba Secure Docs App ID

# Product IDs
MONTHLY_PRODUCT_ID="com.khandoba.premium.monthly"
YEARLY_PRODUCT_ID="com.khandoba.premium.yearly"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Change to script directory
cd "$(dirname "$0")"

echo "📋 Configuration:"
echo "   Key ID: $KEY_ID"
echo "   App ID: $APP_ID"
echo "   Products: Monthly & Yearly"
echo ""

# Generate JWT Token
echo "🔑 Generating JWT token..."
JWT=$(./generate_jwt.sh)

if [ -z "$JWT" ]; then
    echo -e "${RED}❌ Failed to generate JWT token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ JWT token generated${NC}"
echo ""

# Function to create subscription group
create_subscription_group() {
    echo "📦 Creating Subscription Group..."
    
    RESPONSE=$(curl -s -X POST \
        "https://api.appstoreconnect.apple.com/v1/subscriptionGroups" \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        -d '{
            "data": {
                "type": "subscriptionGroups",
                "attributes": {
                    "referenceName": "Khandoba Premium",
                    "app": "'$APP_ID'"
                }
            }
        }')
    
    GROUP_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$GROUP_ID" ]; then
        echo -e "${GREEN}✅ Subscription Group Created: $GROUP_ID${NC}"
        echo "$GROUP_ID"
    else
        echo -e "${YELLOW}⚠️  Group may already exist or error occurred${NC}"
        echo "$RESPONSE"
    fi
}

# Function to create monthly subscription
create_monthly_subscription() {
    GROUP_ID=$1
    echo "📱 Creating Monthly Subscription..."
    
    RESPONSE=$(curl -s -X POST \
        "https://api.appstoreconnect.apple.com/v1/subscriptions" \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        -d '{
            "data": {
                "type": "subscriptions",
                "attributes": {
                    "name": "Khandoba Premium Monthly",
                    "productId": "'$MONTHLY_PRODUCT_ID'",
                    "subscriptionPeriod": "ONE_MONTH",
                    "familySharable": true,
                    "subscriptionGroupId": "'$GROUP_ID'",
                    "reviewNote": "Monthly premium subscription with unlimited vaults, storage, and AI features"
                },
                "relationships": {
                    "group": {
                        "data": {
                            "type": "subscriptionGroups",
                            "id": "'$GROUP_ID'"
                        }
                    }
                }
            }
        }')
    
    echo "$RESPONSE"
}

# Function to create yearly subscription
create_yearly_subscription() {
    GROUP_ID=$1
    echo "📱 Creating Yearly Subscription..."
    
    RESPONSE=$(curl -s -X POST \
        "https://api.appstoreconnect.apple.com/v1/subscriptions" \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        -d '{
            "data": {
                "type": "subscriptions",
                "attributes": {
                    "name": "Khandoba Premium Yearly",
                    "productId": "'$YEARLY_PRODUCT_ID'",
                    "subscriptionPeriod": "ONE_YEAR",
                    "familySharable": true,
                    "subscriptionGroupId": "'$GROUP_ID'",
                    "reviewNote": "Yearly premium subscription with unlimited vaults, storage, and AI features. Save 20% vs monthly."
                },
                "relationships": {
                    "group": {
                        "data": {
                            "type": "subscriptionGroups",
                            "id": "'$GROUP_ID'"
                        }
                    }
                }
            }
        }')
    
    echo "$RESPONSE"
}

# Function to create price point for monthly subscription
create_monthly_price() {
    SUBSCRIPTION_ID=$1
    echo "💰 Creating Monthly Price ($5.99/month)..."
    
    RESPONSE=$(curl -s -X POST \
        "https://api.appstoreconnect.apple.com/v1/subscriptionPricePoints" \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        -d '{
            "data": {
                "type": "subscriptionPricePoints",
                "attributes": {
                    "subscriptionId": "'$SUBSCRIPTION_ID'",
                    "territoryId": "USA",
                    "priceTier": 5
                }
            }
        }')
    
    echo "$RESPONSE"
}

# Function to create price point for yearly subscription
create_yearly_price() {
    SUBSCRIPTION_ID=$1
    echo "💰 Creating Yearly Price ($59.99/year)..."
    
    RESPONSE=$(curl -s -X POST \
        "https://api.appstoreconnect.apple.com/v1/subscriptionPricePoints" \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        -d '{
            "data": {
                "type": "subscriptionPricePoints",
                "attributes": {
                    "subscriptionId": "'$SUBSCRIPTION_ID'",
                    "territoryId": "USA",
                    "priceTier": 60
                }
            }
        }')
    
    echo "$RESPONSE"
}

# Function to list existing subscriptions
list_subscriptions() {
    echo "📋 Listing Existing Subscriptions..."
    
    RESPONSE=$(curl -s -X GET \
        "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/subscriptionGroups" \
        -H "Authorization: Bearer $JWT")
    
    echo "$RESPONSE"
}

# Main menu
echo "Choose an action:"
echo "1) List existing subscriptions"
echo "2) Create subscription group + products"
echo "3) Create monthly subscription only"
echo "4) Create yearly subscription only"
echo "5) Full setup (recommended)"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo ""
        list_subscriptions
        ;;
    2)
        echo ""
        GROUP_ID=$(create_subscription_group)
        sleep 2
        create_monthly_subscription "$GROUP_ID"
        sleep 2
        create_yearly_subscription "$GROUP_ID"
        ;;
    3)
        read -p "Enter Subscription Group ID: " GROUP_ID
        echo ""
        create_monthly_subscription "$GROUP_ID"
        ;;
    4)
        read -p "Enter Subscription Group ID: " GROUP_ID
        echo ""
        create_yearly_subscription "$GROUP_ID"
        ;;
    5)
        echo ""
        echo "🚀 Starting Full Setup..."
        echo ""
        
        GROUP_ID=$(create_subscription_group)
        echo ""
        sleep 2
        
        create_monthly_subscription "$GROUP_ID"
        echo ""
        sleep 2
        
        create_yearly_subscription "$GROUP_ID"
        echo ""
        
        echo -e "${GREEN}✅ Full setup complete!${NC}"
        echo ""
        echo "📝 Next Steps:"
        echo "   1. Go to App Store Connect"
        echo "   2. Navigate to your app → Subscriptions"
        echo "   3. Add localizations and screenshots"
        echo "   4. Submit for review"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "================================"
echo "✅ Done!"
echo ""
echo "📝 Manual Steps Required:"
echo "   1. Visit: https://appstoreconnect.apple.com"
echo "   2. Go to: Apps → Khandoba Secure Docs → Subscriptions"
echo "   3. Add localized descriptions"
echo "   4. Upload subscription screenshots"
echo "   5. Submit for review"
echo ""
echo "Product IDs configured in app:"
echo "   - $MONTHLY_PRODUCT_ID"
echo "   - $YEARLY_PRODUCT_ID"

