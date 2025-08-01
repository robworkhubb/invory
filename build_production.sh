#!/bin/bash

# Invory Production Build Script
# Optimized for performance and size

echo "🚀 Building Invory for Production..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for Web (optimized)
echo "🌐 Building for Web..."
flutter build web \
  --release \
  --web-renderer html \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --dart-define=FLUTTER_WEB_USE_SKIA_RENDERER=false

# Build for Android (optimized)
echo "🤖 Building for Android..."
flutter build apk \
  --release \
  --target-platform android-arm64 \
  --split-per-abi

# Build for iOS (optimized)
echo "🍎 Building for iOS..."
flutter build ios \
  --release \
  --no-codesign

echo "✅ Production builds completed!"
echo ""
echo "📁 Build outputs:"
echo "  Web: build/web/"
echo "  Android: build/app/outputs/flutter-apk/"
echo "  iOS: build/ios/archive/"
echo ""
echo "🚀 Ready for deployment!" 