#!/bin/bash

# Helper script to get SHA-1 fingerprints for Google Sign-In setup
# Usage: ./get_sha1.sh

echo "================================"
echo "📱 Google Sign-In SHA-1 Helper"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -d "android" ]; then
    echo "❌ Error: android directory not found"
    echo "Please run this script from your Flutter project root"
    exit 1
fi

echo "🔍 Getting DEBUG SHA-1 fingerprint..."
echo ""

cd android

# Get debug SHA-1
./gradlew signingReport 2>/dev/null | grep -A 5 "Variant: debug" | grep "SHA1:" | head -1

echo ""
echo "================================"
echo "📋 What to do next:"
echo "================================"
echo ""
echo "1. Copy the SHA1 value above"
echo "2. Go to: https://console.cloud.google.com/"
echo "3. Navigate to: APIs & Services → Credentials"
echo "4. Create or edit your Android OAuth client"
echo "5. Add your package name: com.kanso.mirei.mirei"
echo "6. Paste the SHA-1 fingerprint"
echo "7. Save and wait 5-10 minutes"
echo ""
echo "For release builds, you'll need to use your release keystore:"
echo "  keytool -list -v -keystore path/to/release.keystore -alias your-key-alias"
echo ""

cd ..






