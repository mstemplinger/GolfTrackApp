// pm2-Beschreibung des Webdienstes. Liegt neben den Diensten von TOOB360 und
// BePartOfGreat auf derselben Maschine; der Port ist deshalb ein anderer.
module.exports = {
  apps: [
    {
      name: "golftrack",
      cwd: "/var/www/golftrack",
      script: "node_modules/next/dist/bin/next",
      args: "start -p 3200",
      env_file: "/var/www/golftrack/.env.production",
      exec_mode: "fork",
      instances: 1,
      max_memory_restart: "600M",
      autorestart: true,
      time: true,
    },
  ],
};
