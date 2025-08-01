#!/bin/bash

echo "🚀 Deploying Invory to GitHub Pages..."

# Build dell'app
echo "📦 Building Flutter app..."
flutter build web --release

# Verifica che la build sia andata a buon fine
if [ ! -d "build/web" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build completed successfully!"

# Commit e push delle modifiche
echo "📝 Committing changes..."
git add .
git commit -m "Deploy to GitHub Pages - $(date)"

echo "🚀 Pushing to GitHub..."
git push origin main

echo "🎉 Deploy completed! Your app will be available at:"
echo "   https://your-username.github.io/invory/"
echo ""
echo "⚠️  Remember to:"
echo "   1. Deploy the notification service to Railway"
echo "   2. Update the API URL in fcm_http_service.dart"
echo "   3. Configure GitHub Pages in repository settings" 