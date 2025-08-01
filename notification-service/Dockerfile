# Usa Node.js 18 Alpine per un'immagine più leggera
FROM node:18-alpine

# Imposta la directory di lavoro
WORKDIR /app

# Installa le dipendenze di sistema necessarie
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# Copia i file di configurazione
COPY package*.json ./
COPY env.example ./

# Installa le dipendenze
RUN npm ci --only=production && npm cache clean --force

# Copia il codice sorgente
COPY . .

# Crea la directory per i log
RUN mkdir -p logs

# Crea un utente non-root per sicurezza
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Cambia la proprietà dei file
RUN chown -R nodejs:nodejs /app
USER nodejs

# Esponi la porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Comando di avvio
CMD ["npm", "start"] 