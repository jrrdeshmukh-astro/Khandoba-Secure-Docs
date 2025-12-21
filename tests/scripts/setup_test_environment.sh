#!/bin/bash
# Setup test environment - install missing tools via Homebrew

set -e

echo "🔧 Setting up Test Environment"
echo "================================"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "📦 Installing/Updating required tools..."
echo ""

# Install Xcode Command Line Tools (if not already installed)
if ! xcode-select -p &> /dev/null; then
    echo "📱 Installing Xcode Command Line Tools..."
    xcode-select --install || echo "⚠️  Xcode Command Line Tools installation may require user interaction"
else
    echo "✅ Xcode Command Line Tools already installed"
fi

# Install Swift (if not available)
if ! command -v swift &> /dev/null; then
    echo "📦 Installing Swift..."
    brew install swift || echo "⚠️  Swift installation may require Xcode"
else
    echo "✅ Swift already installed: $(swift --version | head -1)"
fi

# Install Java (for Android)
if ! command -v java &> /dev/null; then
    echo "☕ Installing Java..."
    brew install openjdk@17
    echo "✅ Java installed"
else
    echo "✅ Java already installed: $(java -version 2>&1 | head -1)"
fi

# Install .NET SDK (for Windows)
if ! command -v dotnet &> /dev/null; then
    echo "🔷 Installing .NET SDK..."
    brew install --cask dotnet-sdk
    echo "✅ .NET SDK installed"
else
    echo "✅ .NET SDK already installed: $(dotnet --version)"
fi

# Install xcpretty for better test output (optional)
if ! command -v xcpretty &> /dev/null; then
    echo "📦 Installing xcpretty (optional, for better test output)..."
    gem install xcpretty || echo "⚠️  xcpretty installation failed (optional)"
else
    echo "✅ xcpretty already installed"
fi

echo ""
echo "✅ Test environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: ./tests/scripts/run_all_tests.sh"
echo "2. Or run platform-specific tests:"
echo "   - ./tests/scripts/run_apple_tests.sh"
echo "   - ./tests/scripts/run_android_tests.sh"
echo "   - ./tests/scripts/run_windows_tests.sh"

