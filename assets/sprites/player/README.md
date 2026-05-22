# Sprites del jugador

Coloca aquí tu sprite sheet del pescador.

## Archivo esperado

| Archivo | Descripción |
|---------|-------------|
| `fisherman_sheet.png` | Hoja 4×5 (20 frames), fondo transparente |

## Import en Godot

1. Copia el PNG en esta carpeta.
2. Selecciónalo en el FileSystem → pestaña **Import**.
3. **Filter**: Nearest  
4. **Mipmaps**: Off  
5. Clic en **Reimport**.

## Grid

Hoja **1024×1536** → celdas **256×256**, **4 columnas × 5 filas**.

| Fila | Animación en Godot |
|------|-------------------|
| 0 | `idle_front`, `idle_back`, `walk_front`, `walk_back` |
| 1 | `walk_side_rod` |
| 2 | `walk_side` |
| 3 | `fish_hold` |
| 4 | `fish_reel` |

Las animaciones se generan en código: `scripts/player/player_sprite_frames_builder.gd`.
