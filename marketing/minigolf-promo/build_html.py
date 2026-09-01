#!/usr/bin/env python3
"""
Baut den eigenstaendigen HTML-Player: engine.js + Tonspur in EINE Datei.

    python3 build_html.py

Der Ton haengt am selben Zeitwert wie das Bild, damit im Player exakt das
laeuft, was auch im MP4 steckt. Browser blockieren Autoplay mit Ton, deshalb
gibt es einen Ton-an-Schalter, der die Wiedergabe an der aktuellen Position
aufnimmt statt von vorn zu starten.
"""
import base64
import pathlib

here = pathlib.Path(__file__).parent
engine = (here / "engine.js").read_text(encoding="utf-8")
mp3 = base64.b64encode((here / "score.mp3").read_bytes()).decode("ascii")

HTML = """<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>GolfTrack · Minigolf-Werbefilm</title>
<style>
  :root{ --bg:#08080c; --panel:#101018; --line:#22222e; --ink:#e9e9f2; --dim:#8b8b9c; --accent:#8b3bff; }
  *{box-sizing:border-box}
  html,body{height:100%}
  body{ margin:0; background:var(--bg); color:var(--ink);
    font:14px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;
    display:flex; flex-direction:column; align-items:center; justify-content:center;
    gap:16px; padding:24px; min-height:100vh; }
  #stage{ position:relative; border-radius:18px; overflow:hidden; background:#000;
    box-shadow:0 24px 70px rgba(0,0,0,.7), 0 0 0 1px var(--line); line-height:0; }
  canvas{display:block; width:100%; height:auto;}
  .bar{display:flex; align-items:center; gap:12px; width:100%; max-width:440px;}
  button{ background:var(--panel); color:var(--ink); border:1px solid var(--line);
    padding:9px 16px; border-radius:999px; cursor:pointer; font-size:13px;
    font-weight:600; letter-spacing:.02em; transition:border-color .15s, background .15s; }
  button:hover{border-color:var(--accent); background:#171724}
  button.hot{ border-color:var(--accent); background:#1b1030; color:#fff; }
  input[type=range]{flex:1; accent-color:var(--accent); cursor:pointer}
  .t{font-variant-numeric:tabular-nums; color:var(--dim); font-size:12px; min-width:82px; text-align:right}
  .hint{color:var(--dim); font-size:12px; text-align:center; max-width:460px}
  code{background:var(--panel); padding:1px 6px; border-radius:5px; font-size:11px}
</style>
</head>
<body>

<div id="stage"><canvas id="c"></canvas></div>

<audio id="a" preload="auto" src="data:audio/mpeg;base64,__MP3__"></audio>

<div class="bar">
  <button id="play">Pause</button>
  <button id="sound" class="hot">Ton an</button>
  <input id="seek" type="range" min="0" max="1000" value="0" step="1">
  <span class="t" id="time">0.00 / 0.00</span>
</div>
<div class="hint">Zum Prüfen jedes Frames scrubben. Takt und Texte stehen in
<code>BRAND</code> und <code>TIMELINE</code> in <code>engine.js</code>, die Tonspur in <code>score.py</code>.</div>

<script>
__ENGINE__
</script>

<script>
(function(){
  var cvs = document.getElementById('c');
  cvs.width = PROMO.W; cvs.height = PROMO.H;
  var ctx = cvs.getContext('2d');
  var playBtn = document.getElementById('play');
  var sndBtn  = document.getElementById('sound');
  var seek = document.getElementById('seek');
  var tEl  = document.getElementById('time');
  var audio = document.getElementById('a');

  function fit(){
    var maxH = Math.max(320, window.innerHeight - 200);
    var maxW = Math.min(window.innerWidth - 48, 440);
    var h = Math.min(maxH, maxW * (PROMO.H/PROMO.W));
    document.getElementById('stage').style.width = (h * PROMO.W/PROMO.H) + 'px';
  }
  window.addEventListener('resize', fit); fit();

  var playing = true, t = 0, last = performance.now(), scrubbing = false;
  var soundOn = false, lastSync = 0;

  // Ton an die Bildzeit koppeln. Nicht jeden Frame nachziehen - das erzeugt
  // hoerbares Stottern; nur wenn die Abweichung ueber ~120 ms liegt.
  function syncAudio(force){
    if(!soundOn) return;
    var want = Math.min(t, PROMO.DUR - 0.02);
    if(force || Math.abs(audio.currentTime - want) > 0.12) audio.currentTime = want;
  }

  function enableSound(){
    audio.currentTime = Math.min(t, PROMO.DUR - 0.02);
    audio.play().then(function(){
      soundOn = true;
      sndBtn.textContent = 'Ton aus';
      sndBtn.classList.remove('hot');
      if(!playing) audio.pause();
    }).catch(function(){
      sndBtn.textContent = 'Ton blockiert';
    });
  }
  function disableSound(){
    soundOn = false; audio.pause();
    sndBtn.textContent = 'Ton an';
    sndBtn.classList.add('hot');
  }
  sndBtn.addEventListener('click', function(){ soundOn ? disableSound() : enableSound(); });

  function render(){
    PROMO.drawFrame(ctx, t);
    tEl.textContent = t.toFixed(2) + ' / ' + PROMO.DUR.toFixed(2);
    if(!scrubbing) seek.value = Math.round(t / PROMO.DUR * 1000);
  }

  function loop(now){
    var dt = Math.min(0.05, (now - last)/1000); last = now;
    if(playing){
      t += dt;
      if(t >= PROMO.DUR){ t -= PROMO.DUR; syncAudio(true); }
      if(now - lastSync > 500){ lastSync = now; syncAudio(false); }
    }
    render(); requestAnimationFrame(loop);
  }

  playBtn.addEventListener('click', function(){
    playing = !playing;
    playBtn.textContent = playing ? 'Pause' : 'Play';
    if(soundOn){ playing ? audio.play() : audio.pause(); }
  });
  seek.addEventListener('input', function(){
    scrubbing = true; t = seek.value/1000*PROMO.DUR; render(); syncAudio(true);
  });
  seek.addEventListener('change', function(){ scrubbing = false; });

  requestAnimationFrame(loop);
})();
</script>
</body>
</html>
"""

out = HTML.replace("__ENGINE__", engine).replace("__MP3__", mp3)
path = here / "golftrack-minigolf-20s.html"
path.write_text(out, encoding="utf-8")
print(f"{path.name}  {len(out)/1024:.0f} KB")
