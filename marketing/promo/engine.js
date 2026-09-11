/* ============================================================================
   GolfTrack – Werbefilm, 30 s, 9:16
   Positions-Tracking und Minigolf. Eine reine Funktion: drawFrame(ctx, t).
   ========================================================================== */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.PROMO = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var W = 720, H = 1280, FPS = 30;

  var BRAND = {
    name: 'GolfTrack',
    font: '"Helvetica Neue", Helvetica, "Liberation Sans", Arial, sans-serif',
    ink: '#ffffff',
    accent: '#C9A035',        // Gold der App – Heldenfarbe
    hot: '#35ffa8'            // Mint: „gerade passiert"
  };

  // Farbrollen. Der Bogen läuft kühl → violett → warm, wie es der Stil verlangt.
  var C = {
    mint: '#35ffa8', mintDeep: '#00c47a',
    cyan: '#4ec8ff', blue: '#2f8bff', blueDeep: '#1f4cff',
    violet: '#7a2bff', violetSoft: '#6b5bff',
    magenta: '#ff4ccf', pink: '#ff2f7a',
    gold: '#C9A035', goldHot: '#ffd08a', ember: '#ff8a2b'
  };

  var TIMELINE = [
    { name: 'hook', end: 4.40, fn: sceneHook },
    { name: 'track', end: 8.80, fn: sceneTrack },
    { name: 'geometry', end: 13.00, fn: sceneGeometry },
    { name: 'pivot', end: 17.20, fn: scenePivot },
    { name: 'scorecard', end: 21.40, fn: sceneScorecard },
    { name: 'modes', end: 25.40, fn: sceneModes },
    { name: 'close', end: 30.00, fn: sceneClose }
  ];

  var DUR = TIMELINE[TIMELINE.length - 1].end;

  /* ---- Mathe ------------------------------------------------------------ */
  function clamp(v, a, b) { a = a === undefined ? 0 : a; b = b === undefined ? 1 : b; return v < a ? a : v > b ? b : v; }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function inv(t, a, b) { return clamp((t - a) / (b - a)); }
  function smooth(t) { return t * t * (3 - 2 * t); }
  function easeOut(t) { return 1 - Math.pow(1 - t, 3); }
  function easeOut4(t) { return 1 - Math.pow(1 - t, 4); }
  function easeIn(t) { return t * t * t; }
  function easeInOut(t) { return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; }

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
  /** Farbe über drei Stationen – Licht darf nie länger als ~1,5 s einen Ton halten. */
  function ramp(p, a, b, c) { return p < 0.5 ? mix(a, b, smooth(p * 2)) : mix(b, c, smooth((p - 0.5) * 2)); }
  function rng(seed) { var s = seed; return function () { s = (s * 1664525 + 1013904223) % 4294967296; return s / 4294967296; }; }

  /* ---- Grundformen ------------------------------------------------------ */
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

  /* ---- Schrift ---------------------------------------------------------- */
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
  /** Überschrift mittig, mit weichem Schirm dahinter – Text sitzt nie auf Helligkeit. */
  function headline(ctx, txt, y, size, alpha, col) {
    if (alpha <= 0.004) return;
    ctx.save();
    ctx.globalAlpha = alpha;
    setFont(ctx, '700', size);
    var w = trackW(ctx, txt, 0.5);
    glowE(ctx, W / 2, y - size * 0.32, w * 0.72, size * 1.5, '#000000', 0.85, false);
    ctx.fillStyle = col || BRAND.ink;
    ctx.shadowColor = 'rgba(0,0,0,0.9)'; ctx.shadowBlur = 26;
    trackFill(ctx, txt, (W - w) / 2, y, 0.5);
    ctx.restore();
  }

  /* ---- Kachel ----------------------------------------------------------- */
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

    ctx.save();
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

    ctx.save();
    ctx.globalAlpha = a * bodyA;
    rr(ctx, -h, -h + s * 0.05, s, s, r);
    ctx.shadowColor = 'rgba(0,0,0,0.85)'; ctx.shadowBlur = s * 0.24; ctx.shadowOffsetY = s * 0.09;
    ctx.fillStyle = '#000'; ctx.fill();
    ctx.restore();

    ctx.save();
    ctx.globalAlpha = a * bodyA;
    rr(ctx, -h, -h, s, s, r);
    var bg = ctx.createLinearGradient(-h, -h, h * 0.5, h);
    bg.addColorStop(0, '#181822'); bg.addColorStop(0.42, '#0a0a12'); bg.addColorStop(1, '#020206');
    ctx.fillStyle = bg; ctx.fill();
    ctx.restore();

    ctx.save();
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

    ctx.save();
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
  function ringAt(items, i, p, opt) {
    opt = opt || {};
    var e = easeOut(clamp(p));
    var rad = lerp(opt.r0 || 90, opt.r1 || 415, e);
    var ang = (items[i].angle + clamp(p) * (opt.spin === undefined ? 0.30 : opt.spin)) * 6.2832;
    return {
      x: W / 2 + Math.cos(ang) * rad * (opt.rx || 0.92),
      y: H / 2 + Math.sin(ang) * rad * (opt.ry || 1.34),
      size: items[i].size * lerp(0.46, 1.18, e),
      rot: Math.sin(ang) * 0.12,
      alpha: smooth(inv(p, 0, 0.12)) * (1 - smooth(inv(p, 0.88, 1.0)))
    };
  }

  /* ==========================================================================
     Zeichen: die Formen der App
     ========================================================================== */

  /** Fahnenstange mit Fahne, als Pfad bei Skalierung k um (x,y). */
  function pinPath(ctx, x, y, s, k) {
    k = k || 1;
    var w = 14 * s * k, hgt = 400 * s, fw = 176 * s * k, fh = 96 * s * k;
    ctx.beginPath();
    ctx.rect(x - w / 2, y - hgt, w, hgt);            // Stange
    ctx.moveTo(x + w / 2, y - hgt + 6 * s);           // Fahne
    ctx.lineTo(x + w / 2 + fw, y - hgt + 6 * s + fh / 2);
    ctx.lineTo(x + w / 2, y - hgt + 6 * s + fh);
    ctx.closePath();
  }

  /** Das Logo: Ortsmarke mit Ball, wie das App-Icon. */
  function pinMark(ctx, s, fill) {
    ctx.save();
    ctx.scale(s / 100, s / 100);
    ctx.strokeStyle = fill; ctx.fillStyle = fill;
    ctx.lineWidth = 11; ctx.lineJoin = 'round'; ctx.lineCap = 'round';
    ctx.beginPath();                                   // Tropfenform
    ctx.arc(0, -16, 33, Math.PI * 0.86, Math.PI * 0.14, false);
    ctx.lineTo(0, 46);
    ctx.closePath();
    ctx.stroke();
    ctx.beginPath(); ctx.arc(0, -18, 19, 0, 6.2832); ctx.fill();   // Ball
    ctx.restore();
  }

  /* Symbole für die Kacheln – bewusst schlicht, sie sind 90 px groß. */
  function symFlag(ctx, s, fill) {
    ctx.save(); ctx.scale(s / 100, s / 100);
    ctx.fillStyle = fill; ctx.strokeStyle = fill; ctx.lineWidth = 9; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(-16, 38); ctx.lineTo(-16, -40); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-16, -40); ctx.lineTo(34, -24); ctx.lineTo(-16, -8); ctx.closePath(); ctx.fill();
    ctx.restore();
  }
  function symBall(ctx, s, fill) {
    ctx.save(); ctx.scale(s / 100, s / 100);
    ctx.strokeStyle = fill; ctx.lineWidth = 9;
    ctx.beginPath(); ctx.arc(0, 0, 32, 0, 6.2832); ctx.stroke();
    ctx.fillStyle = fill;
    var pts = [[-13, -12], [4, -16], [17, -2], [-6, 4], [10, 15], [-18, 10]];
    for (var i = 0; i < pts.length; i++) { ctx.beginPath(); ctx.arc(pts[i][0], pts[i][1], 4.6, 0, 6.2832); ctx.fill(); }
    ctx.restore();
  }
  function symTrophy(ctx, s, fill) {
    ctx.save(); ctx.scale(s / 100, s / 100);
    ctx.strokeStyle = fill; ctx.fillStyle = fill; ctx.lineWidth = 9; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    ctx.beginPath(); ctx.moveTo(-22, -34); ctx.lineTo(22, -34); ctx.lineTo(18, 2);
    ctx.quadraticCurveTo(0, 20, -18, 2); ctx.closePath(); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-22, -26); ctx.quadraticCurveTo(-42, -20, -26, -6); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(22, -26); ctx.quadraticCurveTo(42, -20, 26, -6); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, 16); ctx.lineTo(0, 30); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-18, 36); ctx.lineTo(18, 36); ctx.stroke();
    ctx.restore();
  }
  function symQR(ctx, s, fill) {
    ctx.save(); ctx.scale(s / 100, s / 100);
    ctx.strokeStyle = fill; ctx.fillStyle = fill; ctx.lineWidth = 8; ctx.lineJoin = 'round';
    var eye = function (x, y) {
      ctx.strokeRect(x, y, 26, 26);
      ctx.fillRect(x + 8, y + 8, 10, 10);
    };
    eye(-38, -38); eye(12, -38); eye(-38, 12);
    ctx.fillRect(14, 14, 10, 10); ctx.fillRect(30, 14, 8, 8); ctx.fillRect(14, 30, 8, 8);
    ctx.fillRect(30, 30, 10, 10);
    ctx.restore();
  }
  function symWatch(ctx, s, fill) {
    ctx.save(); ctx.scale(s / 100, s / 100);
    ctx.strokeStyle = fill; ctx.lineWidth = 8; ctx.lineJoin = 'round'; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(-14, -40); ctx.lineTo(14, -40); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-14, 40); ctx.lineTo(14, 40); ctx.stroke();
    ctx.beginPath(); ctx.rect(-24, -28, 48, 56); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, -10); ctx.lineTo(0, 2); ctx.lineTo(11, 8); ctx.stroke();
    ctx.restore();
  }
  function symChart(ctx, s, fill) {
    ctx.save(); ctx.scale(s / 100, s / 100);
    ctx.strokeStyle = fill; ctx.lineWidth = 9; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    ctx.beginPath(); ctx.moveTo(-34, 22); ctx.lineTo(-10, -6); ctx.lineTo(8, 10); ctx.lineTo(34, -26); ctx.stroke();
    ctx.beginPath(); ctx.arc(34, -26, 6, 0, 6.2832); ctx.fillStyle = fill; ctx.fill();
    ctx.restore();
  }

  /** Die Laufspur: ein fester, handgesetzter Pfad über das Loch. */
  var TRACK = [
    [0.50, 0.86], [0.47, 0.80], [0.44, 0.74], [0.45, 0.68], [0.49, 0.63],
    [0.55, 0.59], [0.61, 0.555], [0.65, 0.515], [0.63, 0.47], [0.575, 0.44],
    [0.52, 0.415], [0.475, 0.385], [0.455, 0.34], [0.48, 0.295], [0.525, 0.265],
    [0.565, 0.235], [0.575, 0.195], [0.55, 0.165]
  ];
  function trackPoint(i) { return { x: TRACK[i][0] * W, y: TRACK[i][1] * H }; }
  /** Zeichnet den Pfad bis zum Anteil p und liefert den Kopfpunkt. */
  function tracePath(ctx, p) {
    var n = TRACK.length - 1, f = clamp(p) * n, seg = Math.floor(f), frac = f - seg;
    if (seg >= n) { seg = n - 1; frac = 1; }
    ctx.beginPath();
    var a = trackPoint(0); ctx.moveTo(a.x, a.y);
    for (var i = 1; i <= seg; i++) { var q = trackPoint(i); ctx.lineTo(q.x, q.y); }
    var s0 = trackPoint(seg), s1 = trackPoint(seg + 1);
    var hx = lerp(s0.x, s1.x, frac), hy = lerp(s0.y, s1.y, frac);
    ctx.lineTo(hx, hy);
    return { x: hx, y: hy };
  }

  /* ==========================================================================
     Szenen
     ========================================================================== */

  /** 1 · LIT-FORM – dunkle Fahne auf leuchtendem Baldachin. */
  function sceneHook(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.18)) * (1 - smooth(inv(t, dur - 0.12, dur)));
    ctx.save(); ctx.globalAlpha = fade;

    var push = easeOut(inv(t, 0, dur * 0.85));
    var p = inv(t, 0, dur);
    var base = H * 0.70;
    var hue = ramp(p, C.mintDeep, C.mint, C.cyan);

    // Baldachin: das Licht kommt von hinten, nicht aus der Form
    glowE(ctx, W / 2, base + 44, lerp(400, 545, push), lerp(180, 240, push), hue, 0.78 * swell(p));
    glowE(ctx, W / 2, base + 10, lerp(230, 300, push), lerp(84, 116, push), '#ffffff', 0.34 * swell(p));
    glowE(ctx, W / 2 - 150, base + 20, 200, 90, C.mintDeep, 0.30 * swell(p));
    glowE(ctx, W / 2 + 170, base + 20, 210, 92, C.cyan, 0.26 * swell(p));

    // Bodenabfall nach Schwarz
    var fg = ctx.createLinearGradient(0, base, 0, H);
    fg.addColorStop(0, 'rgba(0,0,0,0)'); fg.addColorStop(1, '#000');
    ctx.fillStyle = fg; ctx.fillRect(0, base, W, H - base);

    var s = lerp(0.90, 1.04, push);
    shapeBloom(ctx, function (k) { pinPath(ctx, W / 2 - 26, base, s, k); }, hue, 0.62 * swell(p),
      [[3.4, 0.20], [2.4, 0.28], [1.7, 0.34], [1.25, 0.34]]);
    pinPath(ctx, W / 2 - 26, base, s, 1);
    ctx.fillStyle = '#05070a'; ctx.fill();
    ctx.lineWidth = 2; ctx.strokeStyle = hexa(hue, 0.34); ctx.stroke();

    var tp = inv(t, 0.35, 1.30);
    var per = (1.30 - 0.35) / ('Jeder Schritt zählt'.length + 0.6);
    var nTyped = Math.floor(clamp(tp) * ('Jeder Schritt zählt'.length + 0.6));
    var hold = clamp(1 - (t - (0.35 + nTyped * per)) / 0.25);
    var msg = 'Jeder Schritt zählt';
    setFont(ctx, '700', 62);
    var x = (W - ctx.measureText(msg).width) / 2;
    ctx.save();
    glowE(ctx, W / 2, H * 0.30 - 20, 330, 92, '#000000', 0.8, false);
    ctx.shadowColor = 'rgba(0,0,0,0.85)'; ctx.shadowBlur = 24;
    typeOut(ctx, msg, x, H * 0.30, tp, 62, BRAND.ink, C.mint, hold);
    ctx.restore();

    ctx.restore();
  }

  /** 2 · LINE-DRAW – die Laufspur zeichnet sich selbst. */
  function sceneTrack(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.10)) * (1 - smooth(inv(t, dur - 0.12, dur)));
    ctx.save(); ctx.globalAlpha = fade;

    var p = inv(t, 0, dur);
    var draw = easeOut(inv(t, 0.12, dur * 0.80));
    var hue = ramp(p, C.mint, C.cyan, C.blue);

    glow(ctx, W / 2, H * 0.52, lerp(300, 430, smooth(p)), hue, 0.16 * swell(p));

    // Glut unter der Spur
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    for (var b = 0; b < 3; b++) {
      try { ctx.filter = 'blur(' + (26 - b * 8) + 'px)'; } catch (e) { }
      tracePath(ctx, draw);
      ctx.lineWidth = 26 - b * 7; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
      ctx.strokeStyle = hexa(hue, 0.20 + b * 0.09); ctx.stroke();
    }
    try { ctx.filter = 'none'; } catch (e) { }
    ctx.restore();

    var head = tracePath(ctx, draw);
    ctx.lineWidth = 5; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    ctx.strokeStyle = hexa('#ffffff', 0.92); ctx.stroke();

    // Kopfpunkt
    if (draw < 1) {
      glow(ctx, head.x, head.y, 62, '#ffffff', 0.55);
      glow(ctx, head.x, head.y, 30, hue, 0.9);
      ctx.beginPath(); ctx.arc(head.x, head.y, 7.5, 0, 6.2832);
      ctx.fillStyle = '#ffffff'; ctx.fill();
    }

    headline(ctx, 'Deine Laufspur', H * 0.155, 62, smooth(inv(t, 0.25, 0.75)));
    headline(ctx, 'Meter für Meter mitgeschrieben', H * 0.925, 30,
      smooth(inv(t, 0.9, 1.5)) * 0.75, '#cfe6ff');
    ctx.restore();
  }

  /** 3 · PANEL – Abschlag, Grün und der Fairway-Korridor. */
  function sceneGeometry(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.10)) * (1 - smooth(inv(t, dur - 0.12, dur)));
    ctx.save(); ctx.globalAlpha = fade;

    var p = inv(t, 0, dur);
    var hue = ramp(p, C.cyan, C.blue, C.blueDeep);
    var pw = W * 0.80, ph = H * 0.50, px = (W - pw) / 2, py = H * 0.235;
    var rise = easeOut(inv(t, 0, 0.55));

    ctx.save();
    ctx.translate(W / 2, py + ph / 2);
    ctx.rotate(lerp(-0.05, -0.022, rise));
    ctx.scale(lerp(0.90, 1, rise), lerp(0.90, 1, rise));
    ctx.translate(-W / 2, -(py + ph / 2));

    shapeBloom(ctx, function (k) {
      rr(ctx, W / 2 - pw * k / 2, py + ph / 2 - ph * k / 2, pw * k, ph * k, 34 * k);
    }, hue, 0.26 * swell(p), [[1.9, 0.16], [1.45, 0.20], [1.15, 0.22]]);

    rr(ctx, px, py, pw, ph, 34);
    var pg = ctx.createLinearGradient(px, py, px + pw * 0.5, py + ph);
    pg.addColorStop(0, '#12141c'); pg.addColorStop(0.5, '#080a10'); pg.addColorStop(1, '#020305');
    ctx.fillStyle = pg; ctx.fill();
    ctx.lineWidth = 2; ctx.strokeStyle = hexa(hue, 0.40); ctx.stroke();

    ctx.save();
    rr(ctx, px, py, pw, ph, 34); ctx.clip();

    var teeX = px + pw * 0.30, teeY = py + ph * 0.85;
    var grnX = px + pw * 0.68, grnY = py + ph * 0.18;

    // Korridorband, füllt sich von unten
    var corr = easeOut(inv(t, 1.25, 2.75));
    if (corr > 0.01) {
      ctx.save();
      ctx.globalAlpha = 0.85;
      ctx.beginPath();
      var steps = 26;
      for (var i = 0; i <= steps; i++) {
        var q = i / steps, wq = lerp(26, 74, Math.sin(q * Math.PI)) * corr;
        ctx.lineTo(lerp(teeX, grnX, q) - wq, lerp(teeY, grnY, q));
      }
      for (var j = steps; j >= 0; j--) {
        var q2 = j / steps, wq2 = lerp(26, 74, Math.sin(q2 * Math.PI)) * corr;
        ctx.lineTo(lerp(teeX, grnX, q2) + wq2, lerp(teeY, grnY, q2));
      }
      ctx.closePath();
      var cg = ctx.createLinearGradient(teeX, teeY, grnX, grnY);
      cg.addColorStop(0, hexa(hue, 0.05)); cg.addColorStop(0.5, hexa(hue, 0.26)); cg.addColorStop(1, hexa(hue, 0.07));
      ctx.fillStyle = cg; ctx.fill();
      ctx.lineWidth = 1.6; ctx.strokeStyle = hexa(hue, 0.45); ctx.stroke();
      ctx.restore();
    }

    // Mittellinie
    var mid = easeOut(inv(t, 1.5, 2.9));
    if (mid > 0.01) {
      ctx.save();
      ctx.setLineDash([9, 11]);
      ctx.beginPath(); ctx.moveTo(teeX, teeY);
      ctx.lineTo(lerp(teeX, grnX, mid), lerp(teeY, grnY, mid));
      ctx.lineWidth = 2.4; ctx.strokeStyle = hexa('#ffffff', 0.5); ctx.stroke();
      ctx.restore();
    }

    // Marken: schnappen, nicht einblenden
    var teeIn = inv(t, 0.62, 0.70), grnIn = inv(t, 0.95, 1.03);
    if (teeIn > 0) marker(ctx, teeX, teeY, C.mint, teeIn, 'T');
    if (grnIn > 0) marker(ctx, grnX, grnY, C.goldHot, grnIn, 'G');

    ctx.restore();
    ctx.restore();

    headline(ctx, 'Abschlag, Grün, Fairway', H * 0.145, 54, smooth(inv(t, 0.2, 0.7)));
    headline(ctx, 'Die App leitet sie aus deinen Runden ab', H * 0.855, 28,
      smooth(inv(t, 1.6, 2.2)) * 0.78, '#cfe6ff');
    ctx.restore();
  }

  function marker(ctx, x, y, col, k, letter) {
    var s = lerp(0.5, 1.45, easeOut4(k));
    ctx.save();
    glow(ctx, x, y, 52 * s, col, 0.75 * k);
    ctx.beginPath(); ctx.arc(x, y, 15 * s, 0, 6.2832);
    ctx.fillStyle = '#05070a'; ctx.fill();
    ctx.lineWidth = 3.2; ctx.strokeStyle = col; ctx.stroke();
    setFont(ctx, '700', 17 * s);
    ctx.fillStyle = col;
    ctx.fillText(letter, x - ctx.measureText(letter).width / 2, y + 6 * s);
    ctx.restore();
  }

  /** 4 · SHOCKWAVE + WORDMARK – harter Wechsel zum Minigolf. */
  function scenePivot(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.06)) * (1 - smooth(inv(t, dur - 0.16, dur)));
    ctx.save(); ctx.globalAlpha = fade;

    var p = inv(t, 0, dur);
    var hue = ramp(p, C.violet, C.violetSoft, C.magenta);
    var cy = H * 0.44;

    var rp = inv(t, 0, 1.05);
    if (rp > 0 && rp < 1) {
      var r = lerp(14, 900, rp), th = lerp(60, 210, rp);
      var ra = (1 - smooth(inv(rp, 0.42, 1))) * 0.95;
      var g = ctx.createRadialGradient(W / 2, cy, Math.max(1, r - th), W / 2, cy, r + th * 0.55);
      g.addColorStop(0, hexa(hue, 0));
      g.addColorStop(0.50, hexa(hue, 0.55 * ra));
      g.addColorStop(0.66, hexa(hue, 0.92 * ra));
      g.addColorStop(1, hexa(hue, 0));
      ctx.save(); ctx.globalCompositeOperation = 'lighter';
      ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
      ctx.restore();
    }

    glow(ctx, W / 2, cy, lerp(180, 300, smooth(p)), hue, 0.30 * swell(p));

    // Wortmarke: hält klein und glühend, dann Sprung in zwei Bildern
    var snap = smooth(inv(t, 1.02, 1.09));
    var size = lerp(30, 56, snap);
    var col = snap > 0.5 ? BRAND.ink : mix(C.ember, C.gold, smooth(inv(t, 0.05, 0.95)));
    setFont(ctx, '700', size);
    ctx.fillStyle = col;
    ctx.shadowColor = hexa(snap > 0.5 ? '#ffffff' : C.ember, 0.85);
    ctx.shadowBlur = lerp(32, 14, snap);
    trackFill(ctx, BRAND.name, W / 2 - trackW(ctx, BRAND.name, 1.6) / 2, cy + size * 0.36, 1.6);
    ctx.shadowBlur = 0;

    headline(ctx, 'zählt jetzt auch Minigolf', H * 0.60, 44, smooth(inv(t, 1.25, 1.85)));
    ctx.restore();
  }

  /** 5 · QUERY-PILL – QR, Bahn, Zählkarte. */
  function sceneScorecard(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.10)) * (1 - smooth(inv(t, dur - 0.14, dur)));
    var lines = ['QR-Code scannen', 'Bahn 1 · 2 Schläge', 'Zählkarte für alle'];
    var each = dur / lines.length;
    ctx.save(); ctx.globalAlpha = fade;

    var pg = inv(t, 0, dur);
    glow(ctx, W / 2, H * 0.50, 340, ramp(pg, C.magenta, C.pink, C.ember), 0.14 * swell(pg));

    for (var i = 0; i < lines.length; i++) {
      var t0 = i * each, p = (t - t0) / each;
      if (p < -0.14 || p > 1.10) continue;

      var inP = easeOut(inv(p, -0.05, 0.10));
      var outP = easeIn(inv(p, 0.90, 1.04));
      var slide = lerp(230, 0, inP) - outP * 330;
      var scl = lerp(0.80, 1, inP) * lerp(1, 0.62, outP);
      var alpha = Math.min(1, inP * 2.2) * (1 - smooth(outP));
      if (alpha <= 0.004) continue;

      var hue = [C.magenta, C.pink, C.ember][i];

      setFont(ctx, '700', 38);
      var pw = Math.max(520, ctx.measureText(lines[i]).width + 190), ph = 92;
      var cx = W / 2, cy = H * 0.50 + slide;

      ctx.save();
      ctx.globalAlpha = fade * alpha;
      shapeBloom(ctx, function (k) {
        var bw = pw * (1 + (k - 1) * 0.30) * scl, bh = ph * k * scl;
        rr(ctx, cx - bw / 2, cy - bh / 2, bw, bh, bh / 2);
      }, hue, swell(clamp(p)));

      ctx.translate(cx, cy); ctx.scale(scl, scl); ctx.translate(-cx, -cy);
      rr(ctx, cx - pw / 2, cy - ph / 2, pw, ph, ph / 2);
      ctx.shadowColor = hexa(hue, 1); ctx.shadowBlur = 44;
      ctx.lineWidth = 6; ctx.strokeStyle = hue; ctx.stroke();
      ctx.shadowBlur = 0;
      ctx.fillStyle = '#08080f'; ctx.fill();

      var tp = inv(p, 0.01, 0.46);
      var per = (0.46 - 0.01) * each / (lines[i].length + 0.6);
      var n = Math.floor(clamp(tp) * (lines[i].length + 0.6));
      var hold = clamp(1 - (t - (t0 + 0.01 * each + n * per)) / 0.26);
      typeOut(ctx, lines[i], cx - pw / 2 + 44, cy + 13, tp, 38, BRAND.ink, C.mint, hold);

      // kleines Zeichen rechts in der Pille
      ctx.save();
      ctx.translate(cx + pw / 2 - 58, cy);
      ctx.globalAlpha = 0.9 * smooth(inv(p, 0.1, 0.35));
      [symQR, symFlag, symChart][i](ctx, 46, hexa(hue, 0.95));
      ctx.restore();

      ctx.restore();
    }
    ctx.restore();
  }

  /** 6 · SLAB-RING – was in der Zählkarte steckt. */
  function sceneModes(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.09)) * (1 - smooth(inv(t, dur - 0.10, dur)));
    var syms = [symFlag, symBall, symTrophy, symWatch, symChart, symQR];
    var items = [];
    for (var i = 0; i < 6; i++) items.push({ angle: i / 6 - 0.25, size: 168, symbol: syms[i] });

    ctx.save();
    var p = inv(t, 0, dur * 0.92);
    var pg = inv(t, 0, dur);
    var hue = ramp(pg, C.pink, C.ember, C.gold);

    var b = 1 - smooth(inv(t, 0, 0.34));
    if (b > 0.01) glow(ctx, W / 2, H / 2, lerp(300, 780, 1 - b), hue, 0.75 * b * fade);

    for (var j = 0; j < items.length; j++) {
      var q = ringAt(items, j, p, { r0: 70, r1: 330, ry: 1.16, spin: 0.22 });
      q.alpha = smooth(inv(p, 0, 0.12));      // kein Früh-Ausblenden – das macht der Beat
      slab(ctx, {
        x: q.x, y: q.y, size: q.size, rot: q.rot, alpha: fade * q.alpha,
        c1: '#ffffff', c2: hue, halo: hue, symbol: items[j].symbol
      });
    }

    headline(ctx, 'Serie · Asse · Duell', H / 2 + 12, 52, fade * smooth(inv(t, 1.15, 1.75)));
    headline(ctx, 'Nebenwertungen laufen automatisch mit', H * 0.90, 27,
      fade * smooth(inv(t, 1.3, 1.9)) * 0.78, '#ffd9b8');
    ctx.restore();
  }

  /** 7 · HERO-PEEL + SYMBOL-MORPH – die Kachel wird zum Logo. */
  function sceneClose(ctx, t, dur) {
    var fade = smooth(inv(t, 0, 0.10));
    ctx.save();

    var p = inv(t, 0, dur);
    var hue = ramp(p, C.mint, C.blue, C.gold);
    var centre = easeOut(inv(t, 0, 1.05));

    // die Kachel aus dem Ring wandert herein, wächst und glüht durch die Farben
    var x = lerp(W / 2 + 230, W / 2, centre);
    var y = lerp(H / 2 + 210, H * 0.40, centre);
    var size = lerp(168, 300, easeOut(inv(t, 0.15, 1.6)));

    // Gehäuse löst sich auf, das Zeichen bleibt stehen
    var bodyA = 1 - smooth(inv(t, 2.35, 3.10));
    var morph = smooth(inv(t, 1.75, 2.35));

    glow(ctx, x, y, lerp(240, 430, smooth(p)), hue, 0.34 * swell(p) * fade);

    slab(ctx, {
      x: x, y: y, size: size, alpha: fade, bodyA: bodyA,
      c1: '#ffffff', c2: hue, halo: hue, glowCol: hue,
      symbol: symBall, symbol2: pinMark, morph: morph,
      symbolCol: bodyA < 0.5 ? mix('#ffffff', C.goldHot, 1 - bodyA) : undefined
    });

    // Wortmarke und Zeile darunter
    var wm = smooth(inv(t, 2.55, 2.95));
    if (wm > 0.004) {
      ctx.save();
      ctx.globalAlpha = wm;
      setFont(ctx, '700', 62);
      var w = trackW(ctx, BRAND.name, 2.2);
      ctx.fillStyle = '#ffffff';
      ctx.shadowColor = hexa(C.goldHot, 0.75); ctx.shadowBlur = 26;
      trackFill(ctx, BRAND.name, (W - w) / 2, H * 0.70, 2.2);
      ctx.restore();
    }
    headline(ctx, 'Golf und Minigolf. Eine App.', H * 0.755, 30,
      smooth(inv(t, 2.9, 3.4)) * 0.85, '#e8d5a8');
    headline(ctx, 'Im App Store', H * 0.845, 34, smooth(inv(t, 3.3, 3.8)), C.goldHot);

    // sanftes Ausblenden zum Schwarz
    var out = smooth(inv(t, dur - 0.55, dur));
    if (out > 0) { ctx.fillStyle = hexa('#000000', out); ctx.fillRect(0, 0, W, H); }
    ctx.restore();
  }

  /* ---- Wasserzeichen und Hauptschleife ---------------------------------- */
  function watermark(ctx) {
    var s = 30, track = 2.4;
    ctx.save();
    ctx.globalAlpha = 0.30;
    setFont(ctx, '700', s);
    var w = trackW(ctx, BRAND.name, track);
    ctx.fillStyle = BRAND.ink;
    trackFill(ctx, BRAND.name, W - 52 - w, 92, track);
    ctx.restore();
  }

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
    // Im Abspann stört die Ecke die Wortmarke – dort ausblenden.
    if (t < TIMELINE[TIMELINE.length - 1].end - 4.0) watermark(ctx);
    ctx.restore();
  }

  return {
    W: W, H: H, FPS: FPS, DUR: DUR, BRAND: BRAND, TIMELINE: TIMELINE,
    drawFrame: drawFrame,
    u: {
      clamp: clamp, lerp: lerp, inv: inv, smooth: smooth, easeOut: easeOut,
      easeOut4: easeOut4, easeIn: easeIn, easeInOut: easeInOut,
      hexa: hexa, mix: mix, ramp: ramp, rng: rng, rr: rr, glow: glow, glowE: glowE,
      shapeBloom: shapeBloom, swell: swell, setFont: setFont, trackW: trackW,
      trackFill: trackFill, typeOut: typeOut, slab: slab, ringAt: ringAt
    }
  };
});
