# Zona de Prueba — prototipo FPS Android

Proyecto Godot 4.4.1 independiente, paisaje horizontal y renderizador GL Compatibility para móviles.

## Controles
- Android: joystick táctil izquierdo para moverse; arrastra la mitad derecha para mirar; FIRE dispara; RECARGAR y APUNTAR.
- Escena: galpón de pruebas con cobertura, objetivo inmóvil, arma temporal de geometría propia, munición, salud, sonidos temporales sintetizados de disparo, pasos y recarga y ragdoll físico experimental tras el impacto.

## Assets externos
`ASSETS.md` enlaza candidatos con licencias y notas. El candidato de soldado con 24 animaciones tiene señales de posible procedencia dudosa en comentarios del autor/página, por eso no se incorporó. El soldado riggeado alternativo y el set de arma se deben descargar/revisar antes de integrarse; no están incluidos todavía. El objetivo y rifle de esta build son placeholders explícitos, no assets finales ni modelos IA.

## APK
El workflow manual `.github/workflows/android-apk.yml` exporta APK debug y lo publica como artefacto de GitHub Actions si pasa validación. El APK debug se compiló y pasó la importación de Godot y el smoke test en CI; no se ha probado en teléfono.
