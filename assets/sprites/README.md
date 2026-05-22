# Sprites del juego

```
sprites/
  player/
    fisherman_sheet.png   ← sprite sheet del personaje (4×5)
  fish/
    icon/              ← peces inventario (32×32): pejerrey.png, …
  items/
    icon/              ← caña, carnada inventario (32×32): rod.png, bait.png
  ui/
    coin.png           ← moneda en el HUD
```

## Resumen rápido

| Asset | Carpeta | Nombre del archivo |
|-------|---------|-------------------|
| Moneda | `ui/` | `coin.png` |
| Caña | `items/icon/` | `rod.png` |
| Carnada | `items/icon/` | `bait.png` |
| Peces | `fish/icon/` | `{species_id}.png` (ya configurado) |
| Jugador (sheet) | `player/` | `fisherman_sheet.png` |

Mundo y tienda pueden ir en carpetas nuevas bajo `sprites/` cuando los tengas.
