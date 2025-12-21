#!/bin/bash
# Run comprehensive Apple platform tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APPLE_DIR="$PROJECT_ROOT/platforms/apple"

echo "🧪 Running Apple Platform Tests"
echo "================================"

cd "$APPLE_DIR"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ xcodebuild not found. Installing Xcode Command Line Tools..."
    xcode-select --install || {
        echo "❌ Failed to install Xcode Command Line Tools"
        echo "Please install Xcode from the App Store"
        exit 1
    }
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Installing via Homebrew..."
    brew install swift || {
        echo "❌ Failed to install Swift"
        exit 1
    }
fi

# Get available destinations from xcodebuild
# This ensures we get a valid destination that xcodebuild can use
echo "🔍 Finding compatible device destination..."
DESTINATION_OUTPUT=$(xcodebuild -showdestinations -project "Khandoba Secure Docs.xcodeproj" -scheme "Khandoba Secure Docs" 2>&1)

# Check for physical device first (prefer "Jai Deshmukh's iPhone")
PHYSICAL_DEVICE=$(echo "$DESTINATION_OUTPUT" | grep "platform:iOS" | grep -v "Simulator" | grep "iPhone" | grep "Jai Deshmukh's iPhone" | head -1)
DESTINATION=$(echo "$DESTINATION_OUTPUT" | grep "platform:iOS Simulator" | grep "iPhone" | head -1)

# Prefer physical device if available and matches user's device
if [ -n "$PHYSICAL_DEVICE" ] && echo "$PHYSICAL_DEVICE" | grep -q "Jai Deshmukh's iPhone"; then
    DEVICE_ID=$(echo "$PHYSICAL_DEVICE" | sed -E 's/.*id:([A-F0-9-]+).*/\1/' | head -1)
    DEVICE_NAME=$(echo "$PHYSICAL_DEVICE" | sed -E 's/.*name:([^,}]+).*/\1/' | sed 's/[[:space:]]*$//' | head -1)
    if [ -n "$DEVICE_ID" ]; then
        SIMULATOR_SPEC="platform=iOS,id=$DEVICE_ID"
        echo "📱 Using physical device: $DEVICE_NAME (ID: $DEVICE_ID)"
        echo "⚠️  Note: Physical device testing requires code signing and may take longer"
    else
        DESTINATION="$PHYSICAL_DEVICE"
    fi
fi

# If no physical device selected, use simulator
if [ -z "$SIMULATOR_SPEC" ] && [ -n "$DESTINATION" ]; then
    # Extract device ID from destination (most reliable method)
    DEVICE_ID=$(echo "$DESTINATION" | sed -E 's/.*id:([A-F0-9-]+).*/\1/' | head -1)
    DEVICE_NAME=$(echo "$DESTINATION" | sed -E 's/.*name:([^,}]+).*/\1/' | sed 's/[[:space:]]*$//' | head -1)
    OS_VERSION=$(echo "$DESTINATION" | sed -E 's/.*OS:([0-9.]+).*/\1/' | head -1)
    
    if [ -n "$DEVICE_ID" ]; then
        SIMULATOR_SPEC="platform=iOS Simulator,id=$DEVICE_ID"
        echo "🎯 Using simulator: $DEVICE_NAME (ID: $DEVICE_ID, OS: $OS_VERSION)"
    elif [ -n "$DEVICE_NAME" ] && [ -n "$OS_VERSION" ]; then
        SIMULATOR_SPEC="platform=iOS Simulator,name=$DEVICE_NAME,OS=$OS_VERSION"
        echo "🎯 Using simulator: $DEVICE_NAME (OS: $OS_VERSION)"
    else
        # Fallback: use device ID from simctl
        DEVICE_UUID=$(xcrun simctl list devices available 2>/dev/null | grep "iPhone" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' | head -1)
        if [ -n "$DEVICE_UUID" ]; then
            SIMULATOR_SPEC="platform=iOS Simulator,id=$DEVICE_UUID"
            echo "🎯 Using simulator ID: $DEVICE_UUID"
        else
            echo "⚠️  Could not determine simulator, using generic destination"
            SIMULATOR_SPEC="platform=iOS Simulator,name=Any iOS Simulator Device"
        fi
    fi
elif [ -z "$SIMULATOR_SPEC" ]; then
    echo "⚠️  No compatible simulator found in xcodebuild destinations"
    echo "   Trying to use first available iPhone simulator..."
    DEVICE_UUID=$(xcrun simctl list devices available 2>/dev/null | grep "iPhone" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' | head -1)
    if [ -n "$DEVICE_UUID" ]; then
        SIMULATOR_SPEC="platform=iOS Simulator,id=$DEVICE_UUID"
        echo "🎯 Using simulator ID: $DEVICE_UUID"
    else
        echo "⚠️  No simulator found, using generic destination"
        SIMULATOR_SPEC="platform=iOS Simulator,name=Any iOS Simulator Device"
    fi
fi

# Run tests
echo ""
echo "🚀 Running unit tests..."

# Use xcpretty if available, otherwise use raw xcodebuild output
if command -v xcpretty &> /dev/null; then
    xcodebuild test \
        -project "Khandoba Secure Docs.xcodeproj" \
        -scheme "Khandoba Secure Docs" \
        -destination "$SIMULATOR_SPEC" \
        -only-testing:"Khandoba Secure DocsTests" \
        | xcpretty --test --color || {
        echo "❌ Tests failed"
        exit 1
    }
else
    echo "⚠️  xcpretty not found, using raw xcodebuild output"
    xcodebuild test \
        -project "Khandoba Secure Docs.xcodeproj" \
        -scheme "Khandoba Secure Docs" \
        -destination "$SIMULATOR_SPEC" \
        -only-testing:"Khandoba Secure DocsTests" || {
        echo "❌ Tests failed"
        exit 1
    }
fi

echo ""
echo "✅ All Apple tests passed!"

