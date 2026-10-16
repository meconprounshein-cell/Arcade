# RetroVanta OS

Proyecto de sistema arcade liviano para Raspberry Pi 1 Model B+ (ARMv6, 512 MB), basado inicialmente en una imagen RetroPie funcional.

## Regla principal

El rendimiento es prioritario: velocidad de juego, fluidez, audio HDMI estable y controles correctos por encima de cualquier efecto visual.

## Diseño acordado

- Menú propio, ligero, que inicia siempre en selección de consolas.
- Dos puestos arcade físicos con palanca, seis botones (tres arriba y tres abajo), Start y Select; botón central de encendido/apagado independiente.
- Hasta cuatro jugadores mediante dos mandos USB adicionales en juegos y emuladores compatibles.
- Asistente de configuración de mandos al primer inicio, sin asumir el orden de conexión de los botones USB; perfiles por emulador y juego.
- Mantenimiento oculto, sin opción visible en el menú. Acceso propuesto: Start + Select durante 8 segundos desde selección de consolas.
- Salida de los juegos al menú principal mediante Start + Select durante 2 segundos, sujeta a pruebas con cada emulador.
- Audio exclusivamente por HDMI, con optimización por emulador.
- Juegos 4:3, marco arcade estático y CRT Lite opcional, solo si no perjudica el rendimiento.
- Reutilizar capturas de juegos existentes; crear identidad visual y menús originales.
- Conservar el arranque Linux, emuladores y configuraciones funcionales hasta validar los reemplazos.

## Próximas etapas

1. Diagnóstico de solo lectura de la microSD original: OS, particiones, emuladores, mandos, ROMs, capturas, arranque y audio.
2. Desarrollo y prueba del frontend RetroVanta para Windows y ARMv6.
3. Configuración de controles y salida universal por emulador.
4. Instalación versionada, con copias de seguridad y posibilidad de revertir cambios.
5. Pruebas de fluidez y audio en hardware real antes de incorporar juegos al catálogo.

## Estado

Documentación inicial. Todavía no existe una versión instalable probada.

## Seguridad y derechos

No incluir ROM comerciales, BIOS protegidas, credenciales ni imágenes completas de microSD en este repositorio. Hacer una copia de seguridad de la tarjeta original antes de modificarla.
