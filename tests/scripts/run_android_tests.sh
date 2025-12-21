#!/bin/bash
# Run comprehensive Android platform tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/platforms/android"

echo "🧪 Running Android Platform Tests"
echo "=================================="

cd "$ANDROID_DIR"

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "❌ Java not found. Installing via Homebrew..."
    brew install openjdk@17 || {
        echo "❌ Failed to install Java"
        exit 1
    }
    export JAVA_HOME=$(brew --prefix openjdk@17)
fi

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ]; then
    if [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
    else
        echo "⚠️  ANDROID_HOME not set. Some tests may fail."
        echo "Set ANDROID_HOME to your Android SDK path"
    fi
fi

# Check if Gradle wrapper exists
if [ ! -f "./gradlew" ]; then
    echo "⚠️  Gradle wrapper (gradlew) not found."
    echo "   Attempting to use system gradle..."
    
    if ! command -v gradle &> /dev/null; then
        echo "❌ Gradle not found. Please install Gradle or ensure gradlew exists."
        echo "   Install: brew install gradle"
        exit 1
    fi
    
    GRADLE_CMD="gradle"
else
    chmod +x gradlew
    GRADLE_CMD="./gradlew"
fi

echo "🚀 Running unit tests..."
$GRADLE_CMD test --no-daemon || {
    echo "❌ Tests failed"
    exit 1
}

echo ""
echo "✅ All Android tests passed!"

