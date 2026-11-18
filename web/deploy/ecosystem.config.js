// pm2-Beschreibung des Webdienstes. Liegt neben den Diensten von TOOB360 und
// BePartOfGreat auf derselben Maschine; der Port ist deshalb ein anderer.
module.exports = {
  apps: [
    {
      name: "golftrack",
      cwd: "/var/www/golftrack",
      script: "node_modules/next/dist/bin/next",
      // Kein -H 127.0.0.1: dann haelt Next.js den Rewrite der Middleware auf
      // localhost:3200/bald fuer fremd und liefert 500. Port 3200 sperrt ufw.
      args: "start -p 3200",
      env_file: "/var/www/golftrack/.env.production",
      // Eigener Dienstnutzer statt root (seit 2026-11-14). .next muss ihm
      // gehoeren, damit der Bild-Cache schreiben kann (siehe deploy.sh).
      uid: "golftrack",
      gid: "golftrack",
      exec_mode: "fork",
      instances: 1,
      max_memory_restart: "600M",
      autorestart: true,
      time: true,
    },
  ],
};
