// Assembles mockups/f/f-console.html — the F-direction agent console — from
// f-console.src.html plus the shared brand assets. Fonts, icons and photos are
// lifted verbatim from mockup-e-liquid-glass.html (the same donor the web-*
// surfaces use) so every prototype renders in the same typeface, iconography
// and photography without any asset being inlined twice by hand.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const F = join(here, "..");
const MOCKUPS = join(F, "..");

const donor = readFileSync(join(MOCKUPS, "mockup-e-liquid-glass.html"), "utf8");

// --- fonts: the first <style> block is the four inlined Poppins weights ------
const fonts = donor.match(/<style>@font-face[\s\S]*?<\/style>/)[0];

// --- registries -------------------------------------------------------------
function registry(name) {
  const st = donor.indexOf(`window.${name}={`);
  const en = donor.indexOf("</script>", st);
  const json = donor.slice(st + `window.${name}=`.length, en).trim().replace(/;$/, "");
  return JSON.parse(json);
}
const ICONS = registry("ICONS");
const PHOTOS = registry("PHOTOS");

// Shared runtime — identical contract to mockups/build/build.mjs: icon/photo
// painting, per-surface theme storage, the hash-synced screen router and the
// attribute-driven primitives (data-go/back/seg/sw/chk/row). Kanban drag is the
// one interaction this runtime does not cover; it lives as its own module
// inside f-console.src.html.
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

  var screens=[].slice.call(document.querySelectorAll('.screen'));
  var ids=screens.map(function(s){return s.id;});

  /* Routes are "#/a-dash", not "#a-dash" — a bare fragment matching a section
     id makes the browser scroll that section under the sticky header after
     scripts run; the leading slash matches no element so the jump never
     happens. */
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
    window.scrollTo(0,0);
    if(push!==false && readHash()!==id) writeHash(id);
    document.querySelectorAll('[data-index]').forEach(function(o){ o.classList.remove('is-open'); });
    document.dispatchEvent(new CustomEvent('screenchange',{detail:{id:id}}));
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

const css =
  readFileSync(join(here, "f-tokens.css"), "utf8") +
  "\n" +
  readFileSync(join(here, "f-components.css"), "utf8");

let html = readFileSync(join(F, "f-console.src.html"), "utf8");
html = html
  .replace("<!--FONTS-->", fonts)
  .replace("<!--CSS-->", `<style>\n${css}</style>`)
  .replace("<!--ICONS-->", `<script>window.ICONS=${JSON.stringify(ICONS)};</script>`)
  .replace("<!--PHOTOS-->", `<script>window.PHOTOS=${JSON.stringify(PHOTOS)};</script>`)
  .replace("<!--RUNTIME-->", `<script>${RUNTIME}</script>`);

const out = join(F, "f-console.html");
writeFileSync(out, html);
console.log("f-console".padEnd(12), (html.length / 1024).toFixed(0) + "KB");
