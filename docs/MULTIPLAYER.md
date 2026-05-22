# Multijugador (ENet)

## En el juego

1. **Crear partida (Host)** — escucha en el puerto `4242` (configurable).
2. **Unirse** — IP del host + mismo puerto.
3. **Jugar solo** — partida local sin red.

Cada jugador tiene su inventario y puede pescar. Los demás ven movimiento y animaciones de pesca. La tienda está desactivada en multijugador por ahora.

**Salir de la partida:** `Esc` vuelve al lobby.

## Probar online con amigos (sin Steam)

### Opción recomendada: Tailscale

1. Todos instalan [Tailscale](https://tailscale.com) e inician sesión.
2. El **host** crea partida en el juego.
3. En Tailscale, el host copia su IP `100.x.x.x`.
4. Los demás eligen **Unirse** y pegan esa IP (puerto `4242`).
5. Windows: permitir **Godot** o el `.exe` exportado en el firewall (red privada).

### Opción alternativa: reenvío de puertos

El host abre el puerto **UDP/TCP 4242** en el router hacia su PC y comparte su **IP pública** (no funciona si el ISP usa CGNAT).

## Límites actuales

- Hasta **4** jugadores (1 host + 3 clientes).
- Host autoritativo para spawn de personajes.
- Inventario y pesca son **por jugador** (no sincronizados entre clientes salvo animación).
- Tienda solo en modo solo.
