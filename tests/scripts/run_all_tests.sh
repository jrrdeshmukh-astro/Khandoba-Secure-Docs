#!/bin/bash
# Run all platform tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Running All Platform Tests"
echo "=============================="
echo ""

# Track results
FAILED=0

# Run Apple tests
echo "🍎 Testing Apple Platform..."
echo "----------------------------"
if bash "$SCRIPT_DIR/run_apple_tests.sh"; then
    echo "✅ Apple tests: PASSED"
else
    echo "❌ Apple tests: FAILED"
    FAILED=1
fi
echo ""

# Run Android tests
echo "🤖 Testing Android Platform..."
echo "-------------------------------"
if bash "$SCRIPT_DIR/run_android_tests.sh"; then
    echo "✅ Android tests: PASSED"
else
    echo "❌ Android tests: FAILED"
    FAILED=1
fi
echo ""

# Run Windows tests
echo "🪟 Testing Windows Platform..."
echo "-------------------------------"
if bash "$SCRIPT_DIR/run_windows_tests.sh"; then
    echo "✅ Windows tests: PASSED"
else
    echo "❌ Windows tests: FAILED"
    FAILED=1
fi
echo ""

# Summary
echo "=============================="
if [ $FAILED -eq 0 ]; then
    echo "✅ All platform tests passed!"
    exit 0
else
    echo "❌ Some tests failed. Check output above."
    exit 1
fi

