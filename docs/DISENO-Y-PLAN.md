# RetroVanta OS — diseño aprobado y alcance de implementación

Objetivo: frontend arcade original, ligero para Raspberry Pi 1 Model B+ (ARMv6), conservando RetroPie y sus emuladores. No alterar el sistema de arranque ni sobrescribir configuraciones hasta probar un reemplazo reversible.

## Diseño visual aprobado
- Identidad: televisor CRT negro/bronce, logo RetroVanta, paleta oscura con acentos neón.
- Pantalla: composición 1280x720 lógica, adaptable a resolución física; sin vídeos, fondos animados ni música en menú.
- Carrusel horizontal de **seis consolas**, en este orden: Arcade (116), Mega Drive (30), Super Nintendo (33), NES (50), Neo Geo (54), Master System (25). Total de selección candidata: 308. Mantener el catálogo maestro ya acordado; las cantidades no equivalen a ROMs validadas.
- Listado de juegos vertical, capturas locales reutilizadas; área de previsualización estática. Juegos en 4:3 y marco CRT Lite opcional, condicionado a FPS.
- D-pad/palanca: navegar; botón A: iniciar; B: volver; START: menú; SELECT: opciones. Mantenimiento **invisible**: START+SELECT durante 8 s en menú principal.
- En juegos START+SELECT durante 2 s como salida propuesta, solo después de validarla con cada emulador (evitar interferencias con combinaciones de los juegos).

## Hardware y rendimiento
- Raspberry Pi 1 B+ ARMv6; Raspbian Buster, Linux 5.10.103+; RAM visible 239 MiB, por verificar reserva GPU.
- MAME4ALL, PiFBA, RetroArch y varios libretro cores presentes. No suponer que cada juego es compatible.
- Prioridades: controles y audio HDMI, estabilidad, FPS, carga rápida. Escalar recursos según rendimiento, usar SDL/C++.
- Alimentación: se observó aviso Under-voltage detected. Resolver alimentación antes de atribuir lentitud a software.

## Controles
- Dos paneles arcade: 1 palanca de 8 direcciones, seis botones (3x2), START y SELECT por jugador.
- Hasta dos mandos USB extra cuando cada emulador soporte hasta 4 jugadores.
- No asumir numeración Linux /dev/input/eventX ni orden de conexión: distinguir dispositivos mediante atributos estables y prueba interactiva.
- Conservar los ficheros originales de mapeo; crear respaldo, validar por emulador y por juego, revertir en caso de fallos.
- Revisar: detección de ambos joysticks, seis botones, direcciones, START, SELECT, hotkey de salida, orden P1/P2, perfiles por emulador.

## Fases y criterios de aceptación
1. Auditar configuración real de mandos y GPU, sin cambios (script control-audit.sh).
2. Crear frontend SDL/C++ ejecutable en paralelo a EmulationStation; probar navegación a dos puestos con juego de muestra.
3. Integrar catálogo maestro contra nombres efectivos de ROMs, sin copiar ni publicar ROMs o BIOS.
4. Mapear controles por motor, audio HDMI y salida segura, con copias de seguridad.
5. Prueba de fluidez real; cambio de inicio solo con mecanismo reversible y autorización.

NO subir informes completos de máquina a repositorios públicos: pueden revelar datos privados.
