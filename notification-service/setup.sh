#!/bin/bash

echo "🚀 Setup Invory Notification Service"
echo "=================================="

# Controlla se Node.js è installato
if ! command -v node &> /dev/null; then
    echo "❌ Node.js non è installato. Installa Node.js 18+ e riprova."
    exit 1
fi

echo "✅ Node.js trovato: $(node --version)"

# Installa dipendenze
echo "📦 Installazione dipendenze..."
npm install

# Crea cartella logs se non esiste
mkdir -p logs

# Controlla se il file .env esiste
if [ ! -f .env ]; then
    echo "📝 Creazione file .env..."
    cp env.example .env
    echo "⚠️  Modifica il file .env con le tue configurazioni"
fi

# Controlla se il service account esiste
if [ ! -f firebase-service-account.json ]; then
    echo "⚠️  File firebase-service-account.json non trovato"
    echo "📋 Per ottenere il file:"
    echo "   1. Vai su Firebase Console"
    echo "   2. Project Settings > Service Accounts"
    echo "   3. Generate New Private Key"
    echo "   4. Scarica e rinomina il file in firebase-service-account.json"
    echo "   5. Mettilo nella cartella notification-service/"
fi

echo ""
echo "🎯 Per avviare il servizio:"
echo "   npm run dev    # Sviluppo"
echo "   npm start      # Produzione"
echo ""
echo "🧪 Per testare il servizio:"
echo "   npm test"
echo ""
echo "📡 Il servizio sarà disponibile su: http://localhost:3000"
echo "🔗 Health check: http://localhost:3000/health" 