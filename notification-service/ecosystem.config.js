module.exports = {
  apps: [
    {
      name: 'invory-notification-service',
      script: 'src/server.js',
      instances: 'max', // Usa tutti i core CPU
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        ALLOWED_ORIGINS: 'https://invory-b9a72.web.app'
      },
      // Configurazione logging
      log_file: './logs/combined.log',
      out_file: './logs/out.log',
      error_file: './logs/error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Configurazione restart
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      
      // Configurazione cluster
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
      
      // Configurazione errori
      max_restarts: 10,
      min_uptime: '10s',
      
      // Configurazione performance
      node_args: '--max-old-space-size=1024',
      
      // Configurazione monitoraggio
      pmx: true,
      
      // Configurazione cron
      cron_restart: '0 2 * * *', // Restart alle 2:00 AM ogni giorno
    }
  ],

  deploy: {
    production: {
      user: 'node',
      host: 'your-server.com',
      ref: 'origin/main',
      repo: 'git@github.com:your-username/invory.git',
      path: '/var/www/invory-notification-service',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
}; 