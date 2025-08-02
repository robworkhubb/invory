#!/bin/bash

echo "🚀 Serving Invory Web App..."

# Build dell'app
echo "📦 Building Flutter app..."
flutter build web --release

# Verifica che la build sia andata a buon fine
if [ ! -d "build/web" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build completed successfully!"

# Crea un file di configurazione per il server
cat > build/web/.htaccess << EOF
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
EOF

# Avvia il server dalla directory corretta
echo "🌐 Starting server on http://localhost:8080"
cd build/web
python3 -m http.server 8080 