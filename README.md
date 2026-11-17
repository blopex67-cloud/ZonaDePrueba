# Zona de Prueba — prototipo FPS Android

Proyecto Godot 4.4.1 independiente, horizontal y con renderizador GL Compatibility para móviles.

## Controles
- Android: joystick táctil izquierdo para moverse; arrastra la mitad derecha para mirar; FIRE dispara; RECARGAR y APUNTAR.
- Escena: galpón de prueba, cobertura, soldado riggeado y armado objetivo, munición y sonidos. El objetivo permanece quieto; al recibir impactos cae mediante una animación de raíz (no ragdoll de huesos).

## Modelos 3D
- Modelo de primera persona FPS AK-74M con brazos texturizados y 8 clips (idle, draw, walk, run, shot y recarga); adaptado desde el GLB proporcionado por el usuario.
- Personaje POLICE riggeado y texturizado como objetivo.
- No se generaron estos modelos con IA. Créditos y licencias CC BY 4.0 en `ATTRIBUTION.md`.

## APK
El workflow `.github/workflows/android-apk.yml` exporta APK debug y lo publica como artefacto de GitHub Actions. La build se valida por importación, smoke test y exportación en CI; no equivale a prueba en un teléfono Android físico.
