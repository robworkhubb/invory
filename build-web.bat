@echo off
echo 🔧 Building Invory Web App with FCM Notifications...

REM Set VAPID Key for Firebase Cloud Messaging
set VAPID_KEY=BMDdRanIyEdtiUDMzOON8gLELJbQV_lBfhx_rb_Q5WEJ9GFdtV0ObfPvKFnjOyrPFMTwcgW7wh1FBpf0F2bDE4M

REM Clean previous build
echo 🧹 Cleaning previous build...

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get

REM Build for web with optimizations
echo 🚀 Building web app with FCM support...
flutter build web ^
  --release ^
  --dart-define=VAPID_KEY=%VAPID_KEY% ^
  --dart-define=FLUTTER_WEB_USE_SKIA=false ^
  --dart-define=FLUTTER_WEB_AUTO_DETECT=false ^
  --dart-define=FLUTTER_WEB_USE_SKIA_RENDERER=false ^
  --dart-define=FLUTTER_WEB_USE_CANVASKIT=false

REM Copy service worker to build directory if it doesn't exist
if not exist "build\web\firebase-messaging-sw.js" (
    echo 📋 Copying Firebase Service Worker...
    copy "web\firebase-messaging-sw.js" "build\web\firebase-messaging-sw.js"
)

REM Verify build
echo ✅ Build completed successfully!
echo 📁 Build location: build\web\
echo 🔔 FCM Notifications: Enabled
echo 🌐 Ready for deployment to GitHub Pages

pause