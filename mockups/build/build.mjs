// Assembles the three La Casa web mockups from shared brand assets.
// Sources live beside this file with <!--FONTS-->/<!--ICONS-->/<!--PHOTOS-->/<!--RUNTIME-->
// markers; the assets are lifted verbatim from mockup-e-liquid-glass.html so the
// web surfaces and the mobile prototype render in the same typeface, iconography
// and photography without any of them being inlined twice by hand.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const MOCKUPS = join(here, "..");

const src = readFileSync(join(MOCKUPS, "mockup-e-liquid-glass.html"), "utf8");

// --- fonts: the first <style> block is the four inlined Poppins weights ------
const fonts = src.match(/<style>@font-face[\s\S]*?<\/style>/)[0];

// --- registries -------------------------------------------------------------
function registry(name) {
  const st = src.indexOf(`window.${name}={`);
  const en = src.indexOf("</script>", st);
  const json = src.slice(st + `window.${name}=`.length, en).trim().replace(/;$/, "");
  return JSON.parse(json);
}
const ICONS = registry("ICONS");
const PHOTOS = registry("PHOTOS");

// Shared runtime: icon/photo painting, theme, and the hash-synced screen router.
// Every mockup declares screens as <section class="screen" id="…"> and wires
// navigation purely by attribute (data-go / data-back), so new markup needs no
// new JavaScript — the same contract mockup-e documents at its runtime block.
const RUNTIME = `
(function(){
  var ICONS=window.ICONS||{}, PHOTOS=window.PHOTOS||{};

  function paintIcons(root){
    (root||document).querySelectorAll('[data-i]').forEach(function(el){
      var g=ICONS[el.getAttribute('data-i')]; if(!g||el.firstChild) return;
      /* mockup-e stores the glyph body under the short key "b" (not "body") —
         accept either so this painter works against both shapes. */
      var body=g.b||g.body; if(!body) return;
      el.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 '+(g.w||256)+' '+(g.h||256)+'" fill="currentColor">'+body+'</svg>';
    });
  }
  function paintPhotos(root){
    (root||document).querySelectorAll('[data-ph]').forEach(function(el){
      var u=PHOTOS[el.getAttribute('data-ph')]; if(!u) return;
      if(el.tagName==='IMG'){ if(!el.src) el.src=u; }
      else if(!el.style.backgroundImage){ el.style.backgroundImage='url('+u+')'; }
    });
  }

  /* ---- theme --------------------------------------------------------------
     Each surface declares its own base via data-theme-base (marketplace and
     console are light, the control room is dark) so the first toggle click
     always flips to the *other* theme rather than re-asserting the current one.
     The storage key is per-surface: all three are served from the same origin
     and must not inherit each other's choice. */
  var root=document.documentElement;
  var base=root.getAttribute('data-theme-base')||'light';
  var KEY='lacasa-theme:'+(document.title||'x');
  var stored=null; try{ stored=localStorage.getItem(KEY); }catch(e){}
  if(stored) root.setAttribute('data-theme',stored);
  function toggleTheme(){
    var cur=root.getAttribute('data-theme')||base;
    var next=cur==='dark'?'light':'dark';
    root.setAttribute('data-theme',next);
    try{ localStorage.setItem(KEY,next); }catch(e){}
  }

  /* ---- router ------------------------------------------------------------ */
  var screens=[].slice.call(document.querySelectorAll('.screen'));
  var ids=screens.map(function(s){return s.id;});

  /* Routes are written as "#/listing-detail", not "#listing-detail". A bare
     fragment that matches a section id makes the browser scroll that section
     to the top of the viewport — and it does so *after* scripts run, so the
     first row of content ends up hidden under the sticky header and no amount
     of scrollTo(0,0) at boot wins the race. The leading slash matches nothing,
     so the anchor jump never happens. */
  function readHash(){ return (location.hash||'').replace(/^#\\/?/,''); }
  function writeHash(id){ location.hash='/'+id; }
  function show(id,push){
    if(ids.indexOf(id)<0) id=ids[0];
    screens.forEach(function(s){ s.classList.toggle('is-on', s.id===id); });
    document.querySelectorAll('[data-go]').forEach(function(b){
      b.classList.toggle('is-active', b.getAttribute('data-go')===id);
    });
    document.querySelectorAll('[data-title-for]').forEach(function(t){
      t.hidden = t.getAttribute('data-title-for')!==id;
    });
    var cur=document.getElementById(id);
    if(cur){ var sc=cur.querySelector('[data-scroll]'); if(sc) sc.scrollTop=0; else cur.scrollTop=0; }
    /* Screen ids double as the hash route, so the browser also treats them as
       anchors and scrolls the section to the top of the viewport — which slides
       the first row of content up underneath the sticky header. Routing always
       lands at the top of the document, so just undo the anchor jump. */
    window.scrollTo(0,0);
    if(push!==false && readHash()!==id) writeHash(id);
    document.querySelectorAll('[data-index]').forEach(function(o){ o.classList.remove('is-open'); });
  }
  var stack=[];
  document.addEventListener('click',function(e){
    var go=e.target.closest('[data-go]');
    if(go){ e.preventDefault(); stack.push(readHash()||ids[0]); show(go.getAttribute('data-go')); return; }
    var back=e.target.closest('[data-back]');
    if(back){ e.preventDefault(); var p=stack.pop(); show(p||ids[0]); return; }
    if(e.target.closest('[data-theme-toggle]')){ e.preventDefault(); toggleTheme(); return; }
    var ix=e.target.closest('[data-index-toggle]');
    if(ix){ e.preventDefault(); var o=document.querySelector('[data-index]'); if(o) o.classList.toggle('is-open'); return; }
    if(e.target.matches('[data-index]')){ e.target.classList.remove('is-open'); return; }

    /* generic interactive primitives, all attribute-driven */
    var fav=e.target.closest('[data-fav]');
    if(fav){ e.preventDefault(); fav.classList.toggle('is-on');
      var ic=fav.querySelector('[data-i]');
      if(ic){ ic.setAttribute('data-i', fav.classList.contains('is-on')?'heart-fill':'heart'); ic.innerHTML=''; paintIcons(fav); }
      return; }
    var seg=e.target.closest('[data-seg]');
    if(seg){
      var grp=seg.closest('[data-segs]');
      if(grp){ grp.querySelectorAll('[data-seg]').forEach(function(s){ s.classList.toggle('is-on', s===seg); });
        var panes=document.getElementById(grp.getAttribute('data-panes')||'');
        if(panes) panes.querySelectorAll('[data-pane]').forEach(function(p){
          p.hidden = p.getAttribute('data-pane')!==seg.getAttribute('data-seg'); });
      }
      return;
    }
    var sw=e.target.closest('[data-sw]');
    if(sw){ e.preventDefault(); sw.classList.toggle('is-on'); return; }
    var chk=e.target.closest('[data-chk]');
    if(chk){ e.preventDefault(); chk.classList.toggle('is-on');
      var ci=chk.querySelector('[data-i]');
      if(ci){ ci.style.opacity = chk.classList.contains('is-on')?'1':'0'; }
      return; }
    var row=e.target.closest('[data-row]');
    if(row){ var tb=row.closest('[data-rows]');
      if(tb) tb.querySelectorAll('[data-row]').forEach(function(r){ r.classList.toggle('is-sel', r===row); }); }
  });
  window.addEventListener('hashchange',function(){ show(readHash()||ids[0],false); });

  paintIcons(); paintPhotos();
  show(readHash()||ids[0],false);
})();
`;

const files = ["web-user", "web-agent", "web-admin"];
for (const name of files) {
  let html = readFileSync(join(here, name + ".src.html"), "utf8");
  html = html
    .replace("<!--FONTS-->", fonts)
    .replace("<!--ICONS-->", `<script>window.ICONS=${JSON.stringify(ICONS)};</script>`)
    .replace("<!--PHOTOS-->", `<script>window.PHOTOS=${JSON.stringify(PHOTOS)};</script>`)
    .replace("<!--RUNTIME-->", `<script>${RUNTIME}</script>`);
  const out = join(MOCKUPS, name + ".html");
  writeFileSync(out, html);
  console.log(name.padEnd(12), (html.length / 1024).toFixed(0) + "KB");
}
