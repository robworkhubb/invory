@echo off
echo Building Invory Web App...

REM Set Firebase environment variables
set FIREBASE_API_KEY=AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg
set FIREBASE_AUTH_DOMAIN=invory-b9a72.firebaseapp.com
set FIREBASE_PROJECT_ID=invory-b9a72
set FIREBASE_STORAGE_BUCKET=invory-b9a72.firebasestorage.app
set FIREBASE_MESSAGING_SENDER_ID=524552556806
set FIREBASE_APP_ID=1:524552556806:web:4bae50045374103e684e87
set FIREBASE_MEASUREMENT_ID=G-MTDPNYBZG4

REM Build the web app with environment variables
flutter build web ^
  --dart-define=FIREBASE_API_KEY=%FIREBASE_API_KEY% ^
  --dart-define=FIREBASE_AUTH_DOMAIN=%FIREBASE_AUTH_DOMAIN% ^
  --dart-define=FIREBASE_PROJECT_ID=%FIREBASE_PROJECT_ID% ^
  --dart-define=FIREBASE_STORAGE_BUCKET=%FIREBASE_STORAGE_BUCKET% ^
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=%FIREBASE_MESSAGING_SENDER_ID% ^
  --dart-define=FIREBASE_APP_ID=%FIREBASE_APP_ID% ^
  --dart-define=FIREBASE_MEASUREMENT_ID=%FIREBASE_MEASUREMENT_ID% ^
  --dart-define=VAPID_KEY=%VAPID_KEY% ^
  --dart-define=FCM_PROJECT_ID=%FCM_PROJECT_ID% ^
  --dart-define=FCM_CLIENT_EMAIL=%FCM_CLIENT_EMAIL% ^
  --dart-define=FCM_PRIVATE_KEY=%FCM_PRIVATE_KEY% ^
  --release ^
  --web-renderer html

echo Build completed!
pause