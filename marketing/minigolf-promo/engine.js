/* ============================================================================
   GOLFTRACK — Minigolf-Anlagen · Werbefilm
   20.0s · 720x1280 (9:16) · 30fps
   Pitch: digitale Scorekarte statt Zettel und Bleistift.
   ========================================================================== */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.PROMO = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  /* ========================================================================
     1. CONFIG
     ====================================================================== */
  var W = 720, H = 1280, FPS = 30;

  var BRAND = {
    name: 'GOLFTRACK',
    font: '"Helvetica Neue", Helvetica, "Liberation Sans", Arial, sans-serif',
    ink: '#ffffff',
    accent: '#7a2bff',
    hot: '#35ffa8'
  };

  // Farbbogen: warm (das Alte) -> violett (Marke) -> elektrisch (UI)
  //            -> violett (System) -> magenta (Finale)
  var C = {
    ember: '#ff5c2b', amber: '#ff8a2b', sand: '#ffd08a',
    violet: '#7a2bff', violet2: '#8b3bff', indigo: '#1f4cff',
    blue: '#2f8bff', cyan: '#00d0ff', mint: '#35ffa8',
    magenta: '#ff4ccf', pink: '#ff2f7a'
  };

  var TIMELINE = [
    { name: 'hook',  end: 4.20,  fn: sceneHook },
    { name: 'brand', end: 7.40,  fn: sceneBrand },
    { name: 'pills', end: 11.60, fn: scenePills },
    { name: 'ring',  end: 15.60, fn: sceneRing },
    { name: 'close', end: 20.00, fn: sceneClose }
  ];

  var DUR = TIMELINE[TIMELINE.length - 1].end;

  /* ========================================================================
     2. MATH
     ====================================================================== */
  function clamp(v, a, b) { a = a === undefined ? 0 : a; b = b === undefined ? 1 : b; return v < a ? a : v > b ? b : v; }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function inv(t, a, b) { return clamp((t - a) / (b - a)); }
  function smooth(t) { return t * t * (3 - 2 * t); }
  function easeOut(t) { return 1 - Math.pow(1 - t, 3); }
  function easeOut4(t) { return 1 - Math.pow(1 - t, 4); }
  function easeIn(t) { return t * t * t; }
  function easeInOut(t) { return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; }
  function easeBack(t) { var c = 1.3; return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2); }

  function hexa(h, a) {
    var n = parseInt(h.slice(1), 16);
    return 'rgba(' + ((n >> 16) & 255) + ',' + ((n >> 8) & 255) + ',' + (n & 255) + ',' + a + ')';
  }
  function mix(h1, h2, t) {
    var a = parseInt(h1.slice(1), 16), b = parseInt(h2.slice(1), 16);
    var r = Math.round(lerp((a >> 16) & 255, (b >> 16) & 255, t));
    var g = Math.round(lerp((a >> 8) & 255, (b >> 8) & 255, t));
    var l = Math.round(lerp(a & 255, b & 255, t));
    return '#' + (((1 << 24) + (r << 16) + (g << 8) + l).toString(16).slice(1));
  }
  /* Farbe entlang mehrerer Stops - so hält kein Glow länger als ~1.5s eine Hue */
  function ramp(stops, p) {
    p = clamp(p) * (stops.length - 1);
    var i = Math.min(stops.length - 2, Math.floor(p));
    return mix(stops[i], stops[i + 1], p - i);
  }

  /* ========================================================================
     3. PRIMITIVES
     ====================================================================== */
  function rr(ctx, x, y, w, h, r) {
    r = Math.min(r, Math.abs(w) / 2, Math.abs(h) / 2);
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y); ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r); ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h); ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r); ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
  }

  function glow(ctx, x, y, r, color, a, add) {
    if (r <= 0 || a <= 0) return;
    ctx.save();
    if (add !== false) ctx.globalCompositeOperation = 'lighter';
    var g = ctx.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, hexa(color, a));
    g.addColorStop(0.30, hexa(color, a * 0.55));
    g.addColorStop(0.62, hexa(color, a * 0.18));
    g.addColorStop(1, hexa(color, 0));
    ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2);
    ctx.restore();
  }
  function glowE(ctx, x, y, rx, ry, color, a, add) {
    ctx.save();
    ctx.translate(x, y); ctx.scale(1, ry / rx); ctx.translate(-x, -y);
    glow(ctx, x, y, rx, color, a, add);
    ctx.restore();
  }

  /* Bloom in der Silhouette des Objekts - nicht als weiches Oval dahinter. */
  function shapeBloom(ctx, path, color, amount, layers) {
    layers = layers || [[4.2, 0.26], [3.1, 0.34], [2.2, 0.40], [1.5, 0.44], [1.15, 0.40]];
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    for (var i = 0; i < layers.length; i++) {
      var k = layers[i][0], a = layers[i][1] * amount;
      try { ctx.filter = 'blur(' + (12 + k * 20).toFixed(0) + 'px)'; } catch (e) { }
      path(k);
      ctx.fillStyle = hexa(color, a); ctx.fill();
    }
    try { ctx.filter = 'none'; } catch (e) { }
    ctx.restore();
  }

  function swell(p) {
    var big = Math.sin(clamp(p) * Math.PI);
    var small = 0.5 - 0.5 * Math.cos(clamp(p) * Math.PI * 3.1);
    return 0.34 + 0.50 * big + 0.18 * small * big;
  }

  function setFont(ctx, weight, size) { ctx.font = weight + ' ' + size + 'px ' + BRAND.font; }
  function trackW(ctx, txt, sp) {
    var w = 0; for (var i = 0; i < txt.length; i++) w += ctx.measureText(txt[i]).width + sp;
    return txt.length ? w - sp : 0;
  }
  function trackFill(ctx, txt, x, y, sp) {
    var c = x; for (var i = 0; i < txt.length; i++) { ctx.fillText(txt[i], c, y); c += ctx.measureText(txt[i]).width + sp; }
    return c;
  }

  function typeOut(ctx, txt, x, y, p, size, ink, hot, hotHold) {
    setFont(ctx, '700', size);
    var n = Math.min(txt.length, Math.floor(clamp(p) * (txt.length + 0.6)));
    var cx = x;
    for (var i = 0; i < n; i++) {
      var recent = i >= n - 2 ? (i === n - 1 ? 1 : 0.65) : 0;
      ctx.fillStyle = recent > 0 && hotHold > 0 ? mix(ink, hot, hotHold * recent) : ink;
      ctx.fillText(txt[i], cx, y);
      cx += ctx.measureText(txt[i]).width;
    }
    return { x: cx, done: n >= txt.length, n: n };
  }

  /* Weiches radiales Scrim, damit Typo nie auf einer hellen Stelle sitzt */
  function scrim(ctx, x, y, rx, ry, a) {
    ctx.save();
    ctx.translate(x, y); ctx.scale(1, ry / rx); ctx.translate(-x, -y);
    var g = ctx.createRadialGradient(x, y, 0, x, y, rx);
    g.addColorStop(0, 'rgba(0,0,0,' + a + ')');
    g.addColorStop(0.55, 'rgba(0,0,0,' + (a * 0.72) + ')');
    g.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = g; ctx.fillRect(x - rx, y - rx, rx * 2, rx * 2);
    ctx.restore();
  }

  function slab(ctx, o) {
    var s = o.size, h = s / 2, r = s * 0.325, a = o.alpha === undefined ? 1 : o.alpha;
    var bodyA = o.bodyA === undefined ? 1 : o.bodyA;
    if (a <= 0.004) return;
    ctx.save();
    ctx.globalAlpha = a;
    ctx.translate(o.x, o.y);
    if (o.rot) ctx.rotate(o.rot);
    var g = ctx.createLinearGradient(-h * 0.8, -h, h * 0.8, h);
    g.addColorStop(0, o.c1); g.addColorStop(1, o.c2);

    ctx.save();                                            // Halo
    ctx.globalAlpha = a * bodyA;
    ctx.globalCompositeOperation = 'lighter';
    try { ctx.filter = 'blur(' + (s * 0.185).toFixed(1) + 'px)'; } catch (e) { }
    rr(ctx, -h * 1.05, -h * 1.02, s * 1.10, s * 1.10, r * 1.08);
    var hg = ctx.createLinearGradient(-h, -h, h, h);
    hg.addColorStop(0, hexa(o.halo || o.c2, 0.85));
    hg.addColorStop(0.5, hexa(o.c2, 1));
    hg.addColorStop(1, hexa(o.halo || o.c2, 0.90));
    ctx.fillStyle = hg; ctx.fill();
    try { ctx.filter = 'none'; } catch (e) { }
    ctx.restore();

    ctx.save();                                            // Kontaktschatten
    ctx.globalAlpha = a * bodyA;
    rr(ctx, -h, -h + s * 0.05, s, s, r);
    ctx.shadowColor = 'rgba(0,0,0,0.85)'; ctx.shadowBlur = s * 0.24; ctx.shadowOffsetY = s * 0.09;
    ctx.fillStyle = '#000'; ctx.fill();
    ctx.restore();

    ctx.save();                                            // Glaskörper
    ctx.globalAlpha = a * bodyA;
    rr(ctx, -h, -h, s, s, r);
    var bg = ctx.createLinearGradient(-h, -h, h * 0.5, h);
    bg.addColorStop(0, '#181822'); bg.addColorStop(0.42, '#0a0a12'); bg.addColorStop(1, '#020206');
    ctx.fillStyle = bg; ctx.fill();
    ctx.restore();

    ctx.save();                                            // belichtete Kante
    ctx.globalAlpha = a * bodyA;
    rr(ctx, -h, -h, s, s, r); ctx.clip();
    var eg = ctx.createLinearGradient(-h, -h, h * 0.6, h * 0.9);
    eg.addColorStop(0, hexa(o.c1, 0.75));
    eg.addColorStop(0.30, 'rgba(255,255,255,0.16)');
    eg.addColorStop(0.72, 'rgba(255,255,255,0.03)');
    eg.addColorStop(1, hexa(o.c2, 0.28));
    rr(ctx, -h + s * 0.018, -h + s * 0.018, s - s * 0.036, s - s * 0.036, r * 0.94);
    ctx.lineWidth = s * 0.036; ctx.strokeStyle = eg; ctx.stroke();
    ctx.restore();

    ctx.save();                                            // Symbol
    ctx.shadowColor = hexa(o.glowCol || o.c1, 0.95);
    ctx.shadowBlur = s * (o.glowCol ? 0.40 : 0.30);
    var fill = o.symbolCol || g;
    if (o.symbol2 && o.morph > 0.001) {
      if (o.morph < 0.999) {
        ctx.save(); ctx.globalAlpha = 1 - o.morph;
        ctx.scale(1 - o.morph * 0.35, 1 - o.morph * 0.35);
        o.symbol(ctx, s * 0.84, fill); ctx.restore();
      }
      ctx.save(); ctx.globalAlpha = o.morph;
      ctx.scale(0.68 + o.morph * 0.32, 0.68 + o.morph * 0.32);
      o.symbol2(ctx, s * 0.84, fill); ctx.restore();
    } else {
      o.symbol(ctx, s * 0.84, fill);
    }
    ctx.restore();
    ctx.restore();
  }

  function watermark(ctx) {
    var s = 30, track = 3.4;
    ctx.save();
    ctx.globalAlpha = 0.30;
    setFont(ctx, '700', s);
    var w = trackW(ctx, BRAND.name, track);
    ctx.fillStyle = BRAND.ink;
    ctx.textBaseline = 'alphabetic';
    trackFill(ctx, BRAND.name, W - 54 - w, 92, track);
    ctx.restore();
  }

  /* ========================================================================
     4. SYMBOLE — jeweils zentriert im Ursprung, gezeichnet im 100er-Raum
     ====================================================================== */
  function symWrap(draw) {
    return function (ctx, s, fill) {
      ctx.save();
      ctx.scale(s / 100, s / 100);
      ctx.fillStyle = fill; ctx.strokeStyle = fill;
      ctx.lineCap = 'round'; ctx.lineJoin = 'round';
      draw(ctx);
      ctx.restore();
    };
  }

  // Scorekarte: Raster mit Häkchen-Spalte
  var symCard = symWrap(function (ctx) {
    ctx.lineWidth = 6;
    ctx.beginPath();
    rrp(ctx, -34, -40, 68, 80, 10); ctx.stroke();
    ctx.lineWidth = 5;
    for (var i = 0; i < 3; i++) {
      var y = -18 + i * 18;
      ctx.beginPath(); ctx.moveTo(-22, y); ctx.lineTo(4, y); ctx.stroke();
      ctx.beginPath(); ctx.arc(18, y, 4.5, 0, 6.2832); ctx.fill();
    }
  });

  // Minigolf-Fahne
  var symFlag = symWrap(function (ctx) {
    ctx.lineWidth = 7;
    ctx.beginPath(); ctx.moveTo(-12, 42); ctx.lineTo(-12, -42); ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(-12, -42); ctx.lineTo(36, -26); ctx.lineTo(-12, -8);
    ctx.closePath(); ctx.fill();
    ctx.beginPath(); ctx.ellipse(0, 44, 30, 9, 0, 0, 6.2832); ctx.fill();
  });

  // Pokal
  var symTrophy = symWrap(function (ctx) {
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-24, -38); ctx.lineTo(24, -38); ctx.lineTo(22, -8);
    ctx.quadraticCurveTo(20, 12, 0, 14); ctx.quadraticCurveTo(-20, 12, -22, -8);
    ctx.closePath(); ctx.fill();
    ctx.beginPath(); ctx.moveTo(-24, -30); ctx.quadraticCurveTo(-44, -26, -30, -6); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(24, -30); ctx.quadraticCurveTo(44, -26, 30, -6); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, 14); ctx.lineTo(0, 30); ctx.stroke();
    ctx.beginPath(); rrp(ctx, -20, 30, 40, 11, 5); ctx.fill();
  });

  // Zwei Spieler
  var symPlayers = symWrap(function (ctx) {
    ctx.beginPath(); ctx.arc(-16, -22, 13, 0, 6.2832); ctx.fill();
    ctx.beginPath(); ctx.moveTo(-40, 34); ctx.quadraticCurveTo(-38, 0, -16, 0);
    ctx.quadraticCurveTo(6, 0, 8, 34); ctx.closePath(); ctx.fill();
    ctx.globalAlpha *= 0.62;
    ctx.beginPath(); ctx.arc(22, -26, 11, 0, 6.2832); ctx.fill();
    ctx.beginPath(); ctx.moveTo(4, 34); ctx.quadraticCurveTo(6, -3, 22, -3);
    ctx.quadraticCurveTo(40, -3, 42, 34); ctx.closePath(); ctx.fill();
  });

  // Durchgestrichener Zettel - das Motiv des Films, kein QR/Bezahlen.
  // Blatt statt Bleistift: die groessere Silhouette bleibt bei Kachelgroesse
  // lesbar, und der Strich steht quer dazu statt fast parallel.
  var symNoPaper = symWrap(function (ctx) {
    ctx.lineWidth = 6;
    ctx.beginPath(); rrp(ctx, -29, -38, 58, 76, 8); ctx.stroke();
    ctx.lineWidth = 5;
    for (var i = 0; i < 3; i++) {
      var y = -16 + i * 16;
      ctx.beginPath(); ctx.moveTo(-16, y); ctx.lineTo(16, y); ctx.stroke();
    }
    // Erst ein schwarzer Spalt, dann der Strich - so liest es als "durchgestrichen"
    ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(-42, -42); ctx.lineTo(42, 42);
    ctx.lineWidth = 20; ctx.strokeStyle = '#05050a'; ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-40, -40); ctx.lineTo(40, 40);
    ctx.lineWidth = 9; ctx.strokeStyle = ctx.fillStyle; ctx.stroke();
  });

  // Stoppuhr
  var symClock = symWrap(function (ctx) {
    ctx.lineWidth = 7;
    ctx.beginPath(); ctx.arc(0, 6, 33, 0, 6.2832); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-11, -38); ctx.lineTo(11, -38); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, -38); ctx.lineTo(0, -27); ctx.stroke();
    ctx.lineWidth = 6;
    ctx.beginPath(); ctx.moveTo(0, 6); ctx.lineTo(0, -14); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, 6); ctx.lineTo(17, 14); ctx.stroke();
  });

  // Balkendiagramm
  var symChart = symWrap(function (ctx) {
    var b = [[-34, 8, 20], [-8, -12, 40], [18, -30, 58]];
    for (var i = 0; i < b.length; i++) {
      ctx.globalAlpha = 1 - i * 0.18;
      ctx.beginPath(); rrp(ctx, b[i][0], b[i][1], 20, b[i][2], 6); ctx.fill();
    }
  });

  // Golfball im Loch
  var symBall = symWrap(function (ctx) {
    ctx.lineWidth = 6;
    ctx.beginPath(); ctx.ellipse(0, 24, 40, 13, 0, 0, 6.2832); ctx.stroke();
    ctx.beginPath(); ctx.arc(0, -8, 24, 0, 6.2832); ctx.fill();
  });

  /* rrp: rounded-rect als reiner Pfad (ohne beginPath), für Symbole */
  function rrp(ctx, x, y, w, h, r) {
    r = Math.min(r, Math.abs(w) / 2, Math.abs(h) / 2);
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y); ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r); ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h); ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r); ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
  }

  /* ========================================================================
     5. RING — geteilt zwischen Szene 4 und 5, damit die Kachel "bleibt"
     ====================================================================== */
  var TILES = [
    { angle: -0.25, symbol: symCard,    c1: '#ffffff', c2: C.violet2, halo: C.blue },
    { angle: -0.125, symbol: symPlayers, c1: '#dfe6ff', c2: C.blue,    halo: C.cyan },
    { angle: 0.0,   symbol: symClock,   c1: '#ffffff', c2: C.cyan,    halo: C.mint },
    { angle: 0.125, symbol: symChart,   c1: '#e8ffef', c2: C.mint,    halo: C.cyan },
    { angle: 0.25,  symbol: symTrophy,  c1: '#fff2d8', c2: C.amber,   halo: C.ember },
    { angle: 0.375, symbol: symNoPaper, c1: '#ffffff', c2: C.magenta, halo: C.pink },
    { angle: 0.5,   symbol: symFlag,    c1: '#ffe6f6', c2: C.pink,    halo: C.magenta },
    { angle: 0.625, symbol: symBall,    c1: '#ffffff', c2: C.violet,  halo: C.violet2 }
  ];

  var RING = { r0: 104, r1: 262, rx: 0.94, ry: 1.24, spin: 0.16, size0: 92, size1: 158 };

  function ringPos(i, p) {
    var e = easeOut(clamp(p));
    var rad = lerp(RING.r0, RING.r1, e);
    var ang = (TILES[i].angle + clamp(p) * RING.spin) * 6.2832;
    return {
      x: W / 2 + Math.cos(ang) * rad * RING.rx,
      y: H * 0.47 + Math.sin(ang) * rad * RING.ry,
      size: lerp(RING.size0, RING.size1, e),
      rot: Math.sin(ang) * 0.10
    };
  }

  /* ========================================================================
     6. SZENEN
     ====================================================================== */

  /* --- 1 · LIT-FORM: dunkler Bleistift auf glühendem Baldachin ---------- */
  function pencilPath(ctx, cx, cy, len, wid, rot, k) {
    k = k || 1;
    var L = len * (1 + (k - 1) * 0.16), Wd = wid * k;
    var half = L / 2, hw = Wd / 2;
    var tip = L * 0.30, fer = L * 0.13, ehw = hw * 1.16, r = ehw * 0.42;
    ctx.save();
    ctx.translate(cx, cy); ctx.rotate(rot);
    ctx.beginPath();
    ctx.moveTo(-half + r, -ehw);                       // Radiergummi oben
    ctx.lineTo(-half + fer, -ehw);
    ctx.lineTo(-half + fer, -hw);                      // Zwinge -> Schaft
    ctx.lineTo(half - tip, -hw);
    ctx.lineTo(half, -hw * 0.12);                      // Anspitz
    ctx.lineTo(half, hw * 0.12);
    ctx.lineTo(half - tip, hw);
    ctx.lineTo(-half + fer, hw);
    ctx.lineTo(-half + fer, ehw);
    ctx.lineTo(-half + r, ehw);                        // Radiergummi unten
    ctx.quadraticCurveTo(-half, ehw, -half, ehw - r);
    ctx.lineTo(-half, -ehw + r);
    ctx.quadraticCurveTo(-half, -ehw, -half + r, -ehw);
    ctx.closePath();
    ctx.restore();
  }

  /* Facettenlinie + Zwinge - macht die Silhouette als Bleistift lesbar */
  function pencilDetail(ctx, cx, cy, len, wid, rot) {
    var half = len / 2, hw = wid / 2, tip = len * 0.30, fer = len * 0.13;
    ctx.save();
    ctx.translate(cx, cy); ctx.rotate(rot);
    ctx.lineCap = 'butt';
    ctx.beginPath();                                   // Facette am Schaft
    ctx.moveTo(-half + fer, -hw * 0.30);
    ctx.lineTo(half - tip * 1.02, -hw * 0.30);
    ctx.lineWidth = 2.4; ctx.strokeStyle = hexa(C.sand, 0.30); ctx.stroke();
    ctx.beginPath();                                   // Zwinge
    ctx.moveTo(-half + fer, -hw); ctx.lineTo(-half + fer, hw);
    ctx.lineWidth = 3.0; ctx.strokeStyle = hexa(C.sand, 0.42); ctx.stroke();
    ctx.beginPath();                                   // Anspitz-Kante
    ctx.moveTo(half - tip, -hw); ctx.lineTo(half - tip, hw);
    ctx.lineWidth = 2.6; ctx.strokeStyle = hexa(C.sand, 0.34); ctx.stroke();
    ctx.beginPath();                                   // Mine
    ctx.moveTo(half - tip * 0.30, -hw * 0.30);
    ctx.lineTo(half, -hw * 0.12); ctx.lineTo(half, hw * 0.12);
    ctx.lineTo(half - tip * 0.30, hw * 0.30);
    ctx.closePath();
    ctx.fillStyle = hexa(C.sand, 0.55); ctx.fill();
    ctx.restore();
  }

  function sceneHook(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.16)) * (1 - smooth(inv(t, dur - 0.10, dur)));
    ctx.save(); ctx.globalAlpha = fade;

    var push = easeOut(inv(t, 0, dur * 0.86));           // langsamer Push-in
    var cx = W / 2, cy = H * 0.355;
    var len = lerp(392, 452, push), wid = lerp(58, 67, push);
    var rot = lerp(-0.30, -0.22, push);

    // Baldachin: Licht sammelt sich direkt unter der Silhouette
    var sw = swell(inv(t, 0.05, dur * 0.92));
    glowE(ctx, cx, cy + 66, 430, 190, C.ember, 0.30 * sw);
    glowE(ctx, cx - 170, cy + 40, 250, 150, C.amber, 0.26 * sw);
    glowE(ctx, cx + 190, cy + 34, 240, 145, C.pink, 0.20 * sw);

    // Lichtkegel, der von der Form nach unten fällt
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    var cg = ctx.createLinearGradient(0, cy + 20, 0, cy + 330);
    cg.addColorStop(0, hexa(C.amber, 0.20 * sw));
    cg.addColorStop(0.55, hexa(C.ember, 0.07 * sw));
    cg.addColorStop(1, hexa(C.ember, 0));
    ctx.fillStyle = cg;
    ctx.beginPath();
    ctx.moveTo(cx - 150, cy + 20); ctx.lineTo(cx + 150, cy + 20);
    ctx.lineTo(cx + 330, cy + 340); ctx.lineTo(cx - 330, cy + 340);
    ctx.closePath(); ctx.fill();
    ctx.restore();

    // Bloom in der Bleistift-Silhouette
    shapeBloom(ctx, function (k) { pencilPath(ctx, cx, cy, len, wid, rot, k); },
      ramp([C.amber, C.ember, C.pink], inv(t, 0.2, dur)), 0.62 + 0.38 * sw);

    // Der Bleistift selbst: mattschwarz, nur Kantenlicht
    pencilPath(ctx, cx, cy, len, wid, rot, 1);
    var bg = ctx.createLinearGradient(cx - 200, cy - 90, cx + 200, cy + 90);
    bg.addColorStop(0, '#141018'); bg.addColorStop(0.45, '#08060a'); bg.addColorStop(1, '#020103');
    ctx.fillStyle = bg; ctx.fill();

    ctx.save();                                          // Rim oben links
    pencilPath(ctx, cx, cy, len, wid, rot, 1); ctx.clip();
    pencilPath(ctx, cx, cy, len - 5, wid - 5, rot, 1);
    var rg = ctx.createLinearGradient(cx - 200, cy - 70, cx + 160, cy + 70);
    rg.addColorStop(0, hexa(C.sand, 0.55));
    rg.addColorStop(0.35, 'rgba(255,255,255,0.10)');
    rg.addColorStop(1, hexa(C.ember, 0.22));
    ctx.lineWidth = 3.2; ctx.strokeStyle = rg; ctx.stroke();
    ctx.restore();

    pencilDetail(ctx, cx, cy, len, wid, rot);

    // Typo auf Dunkelheit
    scrim(ctx, W / 2, H * 0.695, 400, 240, 0.72);
    var l1 = 'ZETTEL.', l2 = 'BLEISTIFT.';
    var sz = 82;

    var p1 = inv(t, 0.34, 1.16);
    setFont(ctx, '700', sz);
    var x1 = (W - ctx.measureText(l1).width) / 2;
    var per1 = (1.16 - 0.34) / (l1.length + 0.6);
    var n1 = Math.floor(clamp(p1) * (l1.length + 0.6));
    var h1 = clamp(1 - (t - (0.34 + n1 * per1)) / 0.26);
    ctx.save();
    ctx.shadowColor = hexa(C.sand, 0.5); ctx.shadowBlur = 24;
    typeOut(ctx, l1, x1, H * 0.672, p1, sz, BRAND.ink, BRAND.hot, h1);
    ctx.restore();

    var p2 = inv(t, 1.34, 2.30);
    setFont(ctx, '700', sz);
    var x2 = (W - ctx.measureText(l2).width) / 2;
    var per2 = (2.30 - 1.34) / (l2.length + 0.6);
    var n2 = Math.floor(clamp(p2) * (l2.length + 0.6));
    var h2 = clamp(1 - (t - (1.34 + n2 * per2)) / 0.26);
    ctx.save();
    ctx.shadowColor = hexa(C.sand, 0.5); ctx.shadowBlur = 24;
    typeOut(ctx, l2, x2, H * 0.672 + sz * 1.16, p2, sz, BRAND.ink, BRAND.hot, h2);
    ctx.restore();

    // Nachsatz
    var p3 = smooth(inv(t, 2.62, 3.10));
    if (p3 > 0.01) {
      ctx.save(); ctx.globalAlpha = fade * p3;
      setFont(ctx, '700', 36);
      var l3 = 'Das war einmal.';
      ctx.fillStyle = hexa(C.sand, 0.92);
      var w3 = trackW(ctx, l3, 1.6);
      trackFill(ctx, l3, (W - w3) / 2, H * 0.672 + sz * 1.16 + 78, 1.6);
      ctx.restore();
    }

    ctx.restore();
  }

  /* --- 2 · SHOCKWAVE + WORDMARK-SNAP ----------------------------------- */
  function sceneBrand(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.12)) * (1 - smooth(inv(t, dur - 0.12, dur)));
    ctx.save(); ctx.globalAlpha = fade;

    var cy = H * 0.455;
    var rp = inv(t, 0, 0.92);
    if (rp > 0 && rp < 1) {
      var r = lerp(16, 860, rp), th = lerp(56, 200, rp);
      var ra = (1 - smooth(inv(rp, 0.42, 1))) * 0.95;
      var col = ramp([C.indigo, C.violet, C.violet2], rp);
      var g = ctx.createRadialGradient(W / 2, cy, Math.max(1, r - th), W / 2, cy, r + th * 0.55);
      g.addColorStop(0, hexa(col, 0));
      g.addColorStop(0.50, hexa(col, 0.60 * ra));
      g.addColorStop(0.66, hexa(col, 0.95 * ra));
      g.addColorStop(1, hexa(col, 0));
      ctx.save(); ctx.globalCompositeOperation = 'lighter';
      ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
      ctx.restore();
    }

    // Hintergrundschein, der nach dem Snap atmet
    var sw = swell(inv(t, 0.9, dur));
    glow(ctx, W / 2, cy, lerp(300, 470, easeOut(inv(t, 0.9, dur))),
      ramp([C.violet, C.violet2, C.magenta], inv(t, 0.9, dur)), 0.42 * sw);

    // Wortmarke: hält klein und glutfarben, SNAPPT dann in ~2 Frames
    var snap = smooth(inv(t, 1.02, 1.09));
    var size = lerp(36, 70, snap);
    var col2 = snap > 0.5 ? BRAND.ink : mix('#d81028', C.amber, smooth(inv(t, 0.02, 0.95)));
    setFont(ctx, '700', size);
    ctx.fillStyle = col2;
    ctx.shadowColor = hexa(snap > 0.5 ? '#ffffff' : C.pink, 0.85);
    ctx.shadowBlur = lerp(32, 16, snap);
    ctx.textBaseline = 'alphabetic';
    var track = lerp(2.0, 5.0, snap);
    trackFill(ctx, BRAND.name, W / 2 - trackW(ctx, BRAND.name, track) / 2, cy + size * 0.36, track);
    ctx.shadowBlur = 0;

    // Unterzeile kommt nach dem Snap
    var sp = smooth(inv(t, 1.22, 1.72));
    if (sp > 0.01) {
      ctx.save(); ctx.globalAlpha = fade * sp;
      setFont(ctx, '700', 33);
      var sub = 'Die digitale Scorekarte';
      ctx.fillStyle = hexa('#ffffff', 0.66);
      var ws = trackW(ctx, sub, 1.8);
      trackFill(ctx, sub, (W - ws) / 2, cy + 78 + lerp(14, 0, sp), 1.8);
      ctx.restore();
    }

    ctx.restore();
  }

  /* --- 3 · QUERY-PILL: was die Gäste eintippen -------------------------- */
  function scenePills(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.10)) * (1 - smooth(inv(t, dur - 0.13, dur)));
    var lines = ['Bahn 7 · 3 Schläge', '8 Spieler, 1 Karte', 'Sieger steht fest'];
    var cols = [C.cyan, C.blue, C.violet2];
    var each = dur / lines.length;
    ctx.save(); ctx.globalAlpha = fade;

    for (var i = 0; i < lines.length; i++) {
      var t0 = i * each, p = (t - t0) / each;
      if (p < -0.16 || p > 1.12) continue;

      var inP = easeOut(inv(p, -0.14, 0.14));
      var outP = easeIn(inv(p, 0.86, 1.06));
      var slide = lerp(300, 0, inP) - outP * 330;
      var scl = lerp(0.74, 1, inP) * lerp(1, 0.62, outP);
      var alpha = Math.min(1, inP * 1.6) * (1 - smooth(outP));
      if (alpha <= 0.004) continue;

      var accent = cols[i];
      setFont(ctx, '700', 40);
      var pw = Math.max(566, ctx.measureText(lines[i]).width + 190), ph = 96;
      var cx = W / 2, cy = H * 0.485 + slide;

      ctx.save();
      ctx.globalAlpha = fade * alpha;

      shapeBloom(ctx, function (k) {
        var bw = pw * (1 + (k - 1) * 0.28) * scl, bh = ph * k * scl;
        rr(ctx, cx - bw / 2, cy - bh / 2, bw, bh, bh / 2);
      }, accent, swell(clamp(p)) * 0.58, [[2.6, 0.20], [1.9, 0.28], [1.45, 0.34], [1.16, 0.34]]);

      ctx.translate(cx, cy); ctx.scale(scl, scl); ctx.translate(-cx, -cy);
      rr(ctx, cx - pw / 2, cy - ph / 2, pw, ph, ph / 2);
      ctx.shadowColor = hexa(accent, 1); ctx.shadowBlur = 46;
      ctx.lineWidth = 6.5;
      var sg = ctx.createLinearGradient(cx - pw / 2, cy - ph / 2, cx + pw / 2, cy + ph / 2);
      sg.addColorStop(0, hexa(accent, 0.95));
      sg.addColorStop(0.5, hexa(mix(accent, '#ffffff', 0.35), 1));
      sg.addColorStop(1, hexa(accent, 0.85));
      ctx.strokeStyle = sg; ctx.stroke();
      ctx.shadowBlur = 0;
      ctx.fillStyle = '#07070e'; ctx.fill();

      var tp = inv(p, 0.08, 0.56);
      var per = (0.56 - 0.08) * each / (lines[i].length + 0.6);
      var n = Math.floor(clamp(tp) * (lines[i].length + 0.6));
      var hold = clamp(1 - (t - (t0 + 0.08 * each + n * per)) / 0.26);
      typeOut(ctx, lines[i], cx - pw / 2 + 48, cy + 14, tp, 40, BRAND.ink, BRAND.hot, hold);

      // Häkchen rechts, sobald die Zeile steht
      var ck = smooth(inv(p, 0.60, 0.74));
      if (ck > 0.01) {
        ctx.save();
        ctx.globalAlpha = ck;
        ctx.translate(cx + pw / 2 - 58, cy - 2);
        ctx.strokeStyle = BRAND.hot; ctx.lineWidth = 6;
        ctx.lineCap = 'round'; ctx.lineJoin = 'round';
        ctx.shadowColor = hexa(BRAND.hot, 0.9); ctx.shadowBlur = 18;
        ctx.beginPath();
        ctx.moveTo(-13, 1); ctx.lineTo(-4, 10); ctx.lineTo(14, -11);
        ctx.stroke();
        ctx.restore();
      }
      ctx.restore();
    }
    ctx.restore();
  }

  /* --- 4 · SLAB-RING --------------------------------------------------- */
  function sceneRing(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.10));
    ctx.save();

    var b = 1 - smooth(inv(t, 0, 0.36));                  // Ankunftsblitz
    if (b > 0.01) glow(ctx, W / 2, H * 0.47, lerp(280, 760, 1 - b), C.violet2, 0.80 * b * fade);

    var p = inv(t, 0, 2.55);
    for (var j = 0; j < TILES.length; j++) {
      var q = ringPos(j, p);
      var a = fade * smooth(inv(p, 0, 0.12));
      slab(ctx, {
        x: q.x, y: q.y, size: q.size, rot: q.rot, alpha: a,
        c1: TILES[j].c1, c2: TILES[j].c2, halo: TILES[j].halo,
        symbol: TILES[j].symbol
      });
    }

    // Mitteltext, sobald der Ring geöffnet ist
    var cp = smooth(inv(t, 1.05, 1.60));
    if (cp > 0.01) {
      ctx.save();
      ctx.globalAlpha = fade * cp;
      scrim(ctx, W / 2, H * 0.468, 250, 150, 0.86);
      setFont(ctx, '700', 60);
      var l1 = 'Alles im', l2 = 'Handy.';
      ctx.fillStyle = BRAND.ink;
      ctx.shadowColor = hexa(C.violet2, 0.7); ctx.shadowBlur = 26;
      ctx.fillText(l1, (W - ctx.measureText(l1).width) / 2, H * 0.468 - 6);
      ctx.fillText(l2, (W - ctx.measureText(l2).width) / 2, H * 0.468 + 60);
      ctx.restore();
    }
    ctx.restore();
  }

  /* --- 5 · HERO-PEEL + SYMBOL-MORPH ------------------------------------ */
  function sceneClose(ctx, t, dur) {
    ctx.save();

    // Die sieben anderen Kacheln ziehen sich zurück
    var out = smooth(inv(t, 0, 0.62));
    for (var j = 1; j < TILES.length; j++) {
      var q = ringPos(j, 1);
      slab(ctx, {
        x: q.x, y: q.y - out * 40, size: q.size * (1 - out * 0.25), rot: q.rot,
        alpha: 1 - out,
        c1: TILES[j].c1, c2: TILES[j].c2, halo: TILES[j].halo, symbol: TILES[j].symbol
      });
    }

    // Held: driftet aus der Ringposition in die Mitte und schwillt an
    var h0 = ringPos(0, 1);
    var drift = easeOut(inv(t, 0.05, 1.30));
    var breath = 1 + 0.045 * Math.sin(inv(t, 0.9, dur) * Math.PI * 1.7);
    var push = easeOut(inv(t, 1.20, dur));                // langsamer Push-in
    var hx = lerp(h0.x, W / 2, drift);
    var hy = lerp(h0.y, H * 0.435, drift);
    var hs = lerp(h0.size, 292, drift) * breath * lerp(1, 1.075, push);

    var glowP = inv(t, 0.2, 2.6);
    var gc = ramp([C.blue, C.violet, C.violet2, C.magenta, C.pink], glowP);
    var sw = swell(inv(t, 0.1, 3.0));

    glow(ctx, hx, hy, lerp(200, 440, drift) * breath, gc, 0.50 * sw);

    var morph = smooth(inv(t, 1.82, 2.20));               // Karte -> Fahne
    var dissolve = smooth(inv(t, 2.92, 3.48));            // Container löst sich

    slab(ctx, {
      x: hx, y: hy, size: hs,
      rot: lerp(h0.rot, 0, drift) + 0.022 * Math.sin(inv(t, 0.9, dur) * Math.PI * 1.3),
      alpha: 1, bodyA: 1 - dissolve,
      c1: '#ffffff', c2: gc, halo: gc, glowCol: gc,
      symbol: symCard, symbol2: symFlag, morph: morph
    });

    // Schlusszeile + Wortmarke
    var cta = smooth(inv(t, 2.36, 2.86));
    if (cta > 0.01) {
      ctx.save();
      ctx.globalAlpha = cta;
      scrim(ctx, W / 2, H * 0.755, 340, 180, 0.80);
      var l1 = 'App laden, losspielen.';
      setFont(ctx, '700', 50);
      ctx.fillStyle = BRAND.ink;
      ctx.shadowColor = hexa(gc, 0.85); ctx.shadowBlur = 30;
      ctx.fillText(l1, (W - ctx.measureText(l1).width) / 2, H * 0.742);
      ctx.shadowBlur = 0;
      var l2 = 'Fertig.';
      setFont(ctx, '700', 44);
      ctx.fillStyle = mix(gc, '#ffffff', 0.45);
      ctx.shadowColor = hexa(gc, 0.9); ctx.shadowBlur = 24;
      ctx.fillText(l2, (W - ctx.measureText(l2).width) / 2, H * 0.742 + 62);
      ctx.restore();
    }

    var wm = smooth(inv(t, 3.36, 3.78));
    if (wm > 0.01) {
      ctx.save();
      ctx.globalAlpha = wm;
      setFont(ctx, '700', 46);
      ctx.fillStyle = BRAND.ink;
      ctx.shadowColor = hexa('#ffffff', 0.55); ctx.shadowBlur = 20;
      var tr = 5.0;
      trackFill(ctx, BRAND.name, W / 2 - trackW(ctx, BRAND.name, tr) / 2, H * 0.885, tr);
      ctx.restore();
    }

    ctx.restore();
  }

  /* ========================================================================
     7. MASTER
     ====================================================================== */
  function drawFrame(ctx, t) {
    t = Math.max(0, Math.min(DUR - 0.0001, t));
    ctx.save();
    ctx.globalCompositeOperation = 'source-over';
    ctx.globalAlpha = 1;
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, W, H);
    ctx.textAlign = 'left'; ctx.textBaseline = 'alphabetic';

    var start = 0;
    for (var i = 0; i < TIMELINE.length; i++) {
      if (t < TIMELINE[i].end) { TIMELINE[i].fn(ctx, t - start, TIMELINE[i].end - start); break; }
      start = TIMELINE[i].end;
    }
    watermark(ctx);
    ctx.restore();
  }

  return {
    W: W, H: H, FPS: FPS, DUR: DUR, BRAND: BRAND, TIMELINE: TIMELINE,
    drawFrame: drawFrame
  };
});
