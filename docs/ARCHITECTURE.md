# Arquitectura (preparada para multiplayer)

## Capas

| Capa | Nodos / scripts | Compartido en MP |
|------|-----------------|------------------|
| Mundo | `main.gd`, `river_shore`, `TimeManager`, `WeatherManager`, `FishDatabase` | Sí (servidor) |
| Jugador | `GamePlayer`, `PlayerState`, `FishingController` | Una instancia por peer |
| UI local | HUD, minijuego, tienda | Solo cliente local |

## Jugador local

- Grupo `local_player`: el peer que controla esta máquina.
- `main.gd` enlaza HUD y señales de `FishingController`; no asume un solo jugador en el árbol global.

## Pesca

- `FishingController.try_start_cast()` / `try_hook_bite()` / `resolve_minigame()`: misma API para validación local o RPC en servidor.
- `_session_rng` en el controlador: hoy tira especie/peso al enganchar; mañana el servidor envía el `FishCatch` al cliente.

## Zonas

- `FishingSpot` / `FishingShopZone`: lista de cuerpos dentro del área.
- `ZoneOverlap.find_*_for_body(player)`: consulta por jugador, no “el primer spot del mundo”.

## Autoloads (solo mundo / datos)

- `FishDatabase`, `TimeManager`, `WeatherManager`, `MusicManager`
- **No** usar autoload para inventario ni monedas.

## Próximo paso multiplayer

1. `NetworkManager` + spawn de `player.tscn` por peer.
2. `is_multiplayer_authority()` en `GamePlayer` y `FishingController`.
3. RPCs que llamen a los mismos `try_*` en el servidor.
