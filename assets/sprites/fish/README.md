# Sprites de peces (pixel art)

Coloca aquí los PNG con fondo transparente. El nombre del archivo debe coincidir con `species_id` en `scripts/fishing/fish_database.gd`.

## Sprites de mundo (vista lateral)

| Archivo | Especie | Tamaño sugerido |
|---------|---------|-----------------|
| `pejerrey.png` | Pejerrey | 16×8 – 24×12 px |
| `perca.png` | Perca | 24×12 – 28×14 px |
| `trucha_arcoiris.png` | Trucha arcoíris | 28×12 – 32×14 px |
| `trucha_fario.png` | Trucha fario | 28×12 – 32×14 px |
| `carpa.png` | Carpa | 40×16 – 48×20 px |

Todos mirando hacia la **izquierda** (misma dirección).

## Import en Godot

Selecciona esta carpeta en el FileSystem → Import:

- **Filter**: Off
- **Mipmaps**: Off

## Ruta en código (futuro)

`res://assets/sprites/fish/{species_id}.png`
