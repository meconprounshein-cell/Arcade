#!/usr/bin/env bash
# RetroVanta: seis identidades originales de consola en el carrusel CRT
# Instalacion reversible, no modifica ROMs ni controles.
set -euo pipefail
THEME="$HOME/.emulationstation/themes/retrovanta"
if pgrep -x emulationstation >/dev/null 2>&1; then
 echo "Cerra EmulationStation (START > QUIT) y volve a ejecutar."
 exit 1
fi
if [ ! -s "$THEME/fondo.png" ]; then
 echo "No se encuentra el fondo CRT instalado: $THEME/fondo.png"
 echo "Instala primero menu-aplicar-crt.sh"
 exit 1
fi
BACK="$HOME/retrovanta-backups/seis-sistemas-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACK"
cp -a "$THEME" "$BACK/tema-anterior"
export RV_DIR="$THEME"
python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET
from html import escape
import os

root = Path(os.environ["RV_DIR"])
# Identidades originales: ni logos comerciales ni personajes propietarios.
systems={
 "arcade":("ARCADE", "#ff862d", "arcade"),
 "fba":("ARCADE", "#ff862d", "arcade"),
 "mame-libretro":("ARCADE", "#ff862d", "arcade"),
 "mame-mame4all":("ARCADE", "#ff862d", "arcade"),
 "megadrive":("MEGA DRIVE", "#2dccff", "megadrive"),
 "snes":("SUPER NINTENDO", "#d17bff", "snes"),
 "nes":("NES", "#ffd255", "nes"),
 "neogeo":("NEO GEO", "#5fe3a8", "neogeo"),
 "mastersystem":("MASTER SYSTEM", "#ff7474", "mastersystem"),
}
# Forma SVG ligera, sin filtros, sombras ni tipografias externas.
def rect(x,y,w,h,fill,rx=0,stroke=None,sw=3):
    return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"%s/>'%(x,y,w,h,rx,fill,(' stroke="%s" stroke-width="%s"'%(stroke,sw)) if stroke else '')
def circle(x,y,r,fill,stroke=None,sw=3):
    return '<circle cx="%s" cy="%s" r="%s" fill="%s"%s/>'%(x,y,r,fill,(' stroke="%s" stroke-width="%s"'%(stroke,sw)) if stroke else '')
def line(x1,y1,x2,y2,color,sw=3):
    return '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>'%(x1,y1,x2,y2,color,sw)
def txt(x,y,s,sz=32,color="#ffffff",weight="bold",anchor="middle"):
    return '<text x="%s" y="%s" font-family="DejaVu Sans,sans-serif" font-size="%s" font-weight="%s" text-anchor="%s" fill="%s">%s</text>'%(x,y,sz,weight,anchor,color,escape(s))
def art(kind,accent):
    a=[]
    # Campo central transparente, deja visible la television original CRT.
    a += [rect(5,5,990,550,"#081326",22,accent,5),
          rect(18,18,964,524,"#10142c",18,"#2b3e68",2)]
    for i in range(9):
        a.append(line(36,420+i*13,970,420+i*13,"#24335b",1))
    for i in range(11):
        a.append(line(50+i*90,420,500+(i-5)*155,530,"#263562",1))
    a += [circle(500,245,175,"#28174e"),circle(500,245,125,"#4b1f5c")]
    if kind=="arcade":
        # maquina arcade con palanca y seis botones
        a += ['<path d="M360 100 L628 100 L656 155 L637 380 L605 445 L392 445 L360 375 L340 175 Z" fill="#151c39" stroke="%s" stroke-width="9"/>'%accent,
              rect(362,116,263,60,"#291932",8,accent,4),
              txt(493,158,"RETROVANTA",27,accent),
              rect(376,190,236,138,"#020d21",12,"#2cdcff",6)]
        for x,y in [(408,218),(463,247),(525,211),(561,265),(439,292)]:
            a.append(rect(x,y,22,22,"#2bddff",3))
        a += ['<path d="M366 350 L626 350 L660 403 L335 403 Z" fill="#253457" stroke="%s" stroke-width="5"/>'%accent,
              circle(426,374,14,"#ed4b5b"),line(426,362,426,340,"#ddd",8)]
        for x,y,c in [(490,370,"#19def0"),(525,378,"#eec94e"),(561,370,"#f55a88"),(500,391,"#25d1aa"),(542,392,"#8f75fa")]:
            a.append(circle(x,y,11,c))
        a += [rect(395,408,215,29,"#090c17",3),rect(485,413,25,15,"#ffd255",2)]
    elif kind=="megadrive":
        a += [circle(495,300,165,"#080c1d",accent,10),
              rect(286,287,417,121,"#0b0f20",42,accent,8),
              rect(340,316,306,63,"#202840",25,"#56699d",4),
              circle(495,294,83,"#0a1124","#d9e7fc",9),
              circle(495,294,49,"#162d50",accent,8),
              txt(495,304,"16 BIT",23,accent)]
        a += [rect(365,418,260,65,"#1b223e",29,accent,4)]
        for x,y in [(437,451),(475,438),(475,464),(514,451)]:a.append(circle(x,y,9,"#eeeeee"))
        for x,y in [(558,440),(584,451),(557,464)]:a.append(circle(x,y,11,"#ee6a8c"))
    elif kind=="snes":
        a += [rect(270,252,465,187,"#d4d5e6",65,"#f9f9ff",6),
              rect(335,280,328,71,"#9499b9",25),
              rect(350,290,300,52,"#5a628c",23),
              rect(310,368,385,39,"#b9bad8",18)]
        for x,y in [(586,374),(619,371),(586,400),(619,396)]:
            a.append(circle(x,y,13,("#7c56e5" if x==586 else "#e76dbc")))
        a += [rect(355,443,282,76,"#e6e4ef",34,accent,5),rect(413,473,67,13,"#7d789a",3)]
        for x,y in [(534,467),(562,480),(535,493),(507,480)]:a.append(circle(x,y,12,accent))
    elif kind=="nes":
        a += [rect(260,265,478,180,"#d7d5ce",8,"#fff9e8",6),
              rect(260,313,478,86,"#393d45",5),
              rect(305,276,342,29,"#9b9b9c",3),
              rect(335,338,315,16,"#0e1019",2),
              rect(376,411,265,17,"#c3c3c3",2)]
        a += [rect(352,456,294,65,"#bfc0be",6,accent,4),
              rect(385,468,23,44,"#252930"),rect(375,480,43,17,"#252930"),
              circle(573,484,14,"#b9212d"),circle(603,484,14,"#b9212d")]
    elif kind=="neogeo":
        a += [rect(300,255,409,181,"#111a27",19,accent,7),
              circle(505,342,114,"#1d3040",accent,8),
              circle(505,342,72,"#08121a","#cad8d7",5),
              txt(505,350,"24",55,accent),
              txt(505,383,"BIT",22,"#e8f9f8"),
              rect(360,459,290,59,"#101a27",28,accent,4)]
        for x,y in [(400,489),(433,477),(433,500),(466,488)]:a.append(circle(x,y,11,"#e9fcf2"))
        for x,y,c in [(553,479,"#ff5f67"),(580,488,"#ffd46f"),(608,477,"#62dba8"),(608,500,"#5dd0f0")]:a.append(circle(x,y,11,c))
    elif kind=="mastersystem":
        a += [rect(278,258,450,182,"#1b1b24",14,"#e2e2ee",7),
              rect(307,282,392,30,"#bf3338",5),
              rect(324,333,356,73,"#242934",9,accent,4),
              rect(338,350,320,22,"#13151f",5),
              rect(363,424,274,16,"#d4d6e4",2)]
        a += [rect(346,464,307,62,"#252733",12,accent,4),
              rect(397,477,21,37,"#0a0f19"),rect(388,490,40,13,"#0a0f19"),
              circle(555,491,13,"#df494d"),circle(583,491,13,"#df494d")]
    return ''.join(a)
def svg_body(s,accent,kind):
    elements=art(kind,accent)
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="560" viewBox="0 0 1000 560">'
           +elements+'</svg>')
def logo_svg(title,accent):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="840" height="144" viewBox="0 0 840 144">'
            +rect(8,13,824,117,"#070b1c",18,accent,7)
            +line(48,113,791,113,"#30466b",3)
            +txt(420,94,title,52,accent)
            +'</svg>')
# Estos codigos SVG son originales y no contienen marcas oficiales.
for system,(label,accent,kind) in systems.items():
    d=root/system
    d.mkdir(exist_ok=True)
    (d/'art.svg').write_text(svg_body(label,accent,kind),encoding="utf-8")
    (d/'logo.svg').write_text(logo_svg(label,accent),encoding="utf-8")
    path=str((root/'fondo.png').resolve())
    xml='''<theme>
<formatVersion>3</formatVersion>
<view name="system">
  <image name="background"><pos>0 0</pos><size>1 1</size><path>'''+path+'''</path></image>
  <image name="rv_crt" extra="true"><pos>0 0</pos><size>1 1</size><path>'''+path+'''</path><zIndex>1</zIndex></image>
  <image name="rv_system_art" extra="true"><pos>0.172 0.294</pos><size>0.618 0.462</size><path>./art.svg</path><zIndex>3</zIndex></image>
  <image name="logo"><path>./logo.svg</path></image>
  <carousel name="systemcarousel">
    <type>horizontal</type><pos>0.265 0.765</pos><size>0.43 0.080</size>
    <logoSize>0.40 0.074</logoSize><logoScale>1</logoScale>
    <maxLogoCount>1</maxLogoCount><color>08102000</color>
  </carousel>
  <text name="systemInfo"><pos>0.2 0.87</pos><size>0.6 0.02</size><color>FFFFFF00</color></text>
</view>
<view name="basic, detailed">
  <image name="background"><pos>0 0</pos><size>1 1</size><path>'''+path+'''</path></image>
  <image name="rv_crt" extra="true"><pos>0 0</pos><size>1 1</size><path>'''+path+'''</path><zIndex>1</zIndex></image>
  <textlist name="gamelist">
   <pos>0.17 0.425</pos><size>0.235 0.315</size>
   <primaryColor>FFFFFF</primaryColor><secondaryColor>A6B5CC</secondaryColor>
   <selectedColor>FFCA4A</selectedColor><selectorColor>263F68</selectorColor>
   <fontSize>0.025</fontSize>
  </textlist>
</view>
<view name="detailed">
  <image name="md_image"><pos>0.438 0.43</pos><maxSize>0.336 0.275</maxSize></image>
  <text name="md_description"><pos>0.441 0.71</pos><size>0.33 0.063</size><fontSize>0.018</fontSize><color>D7E2F3</color></text>
</view>
</theme>'''
    (d/'theme.xml').write_text(xml,encoding='utf-8')
    ET.parse(str(d/'theme.xml'))
    ET.parse(str(d/'art.svg'))
    ET.parse(str(d/'logo.svg'))
    print('LISTO:',system,'-',label)
print('Seis familias graficas instaladas; alias arcade comparten identidad.')
print('No se tocaron las ROMs, los controles ni la lista de sistemas.')
PY
echo "INSTALADO. Respaldo: $BACK"
echo "Inicia EmulationStation; la calesita mostrara una consola a la vez."
