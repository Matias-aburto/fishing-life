extends Control

@onready var _address_field: LineEdit = %AddressField
@onready var _port_field: LineEdit = %PortField
@onready var _status_label: Label = %StatusLabel
@onready var _host_button: Button = %HostButton
@onready var _join_button: Button = %JoinButton
@onready var _solo_button: Button = %SoloButton


func _ready() -> void:
	_port_field.text = str(NetworkManager.DEFAULT_PORT)
	_set_status("Host: crea partida. Join: IP del host (Tailscale 100.x.x.x).")
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)


func _on_host_pressed() -> void:
	_set_buttons_enabled(false)
	var port := _parse_port()
	var err := NetworkManager.start_hosted_game(port)
	if err != OK:
		_set_status("No se pudo crear el servidor (puerto %d)." % port)
		_set_buttons_enabled(true)


func _on_join_pressed() -> void:
	var address := _address_field.text.strip_edges()
	if address.is_empty():
		_set_status("Escribe la IP del host.")
		return
	_set_buttons_enabled(false)
	_set_status("Conectando a %s…" % address)
	var err := NetworkManager.join_game(address, _parse_port())
	if err != OK:
		_set_status("Error al iniciar cliente.")
		_set_buttons_enabled(true)


func _on_solo_pressed() -> void:
	NetworkManager.start_solo()


func _on_connected() -> void:
	_set_status("Conectado. Cargando mundo…")


func _on_connection_failed() -> void:
	_set_status("Conexión fallida. Revisa IP, puerto y firewall.")
	_set_buttons_enabled(true)


func _on_server_disconnected() -> void:
	_set_status("Se perdió la conexión con el host.")
	_set_buttons_enabled(true)


func _parse_port() -> int:
	return clampi(_port_field.text.to_int(), 1, 65535) if _port_field.text.is_valid_int() else NetworkManager.DEFAULT_PORT


func _set_status(text: String) -> void:
	_status_label.text = text


func _set_buttons_enabled(enabled: bool) -> void:
	_host_button.disabled = not enabled
	_join_button.disabled = not enabled
	_solo_button.disabled = not enabled
