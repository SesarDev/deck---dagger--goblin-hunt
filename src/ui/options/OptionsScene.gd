extends Control

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var vsync_check: CheckBox = %VsyncCheck
@onready var btn_back: Button = %BtnBack

# Estado en memoria (persistencia más adelante)
var settings := {
	"music": 70,
	"sfx": 70,
	"fullscreen": false,
	"vsync": true
}

func _ready() -> void:
	_apply_to_ui()
	_connect_signals()

func _apply_to_ui() -> void:
	music_slider.value = settings["music"]
	sfx_slider.value = settings["sfx"]
	fullscreen_check.button_pressed = settings["fullscreen"]
	vsync_check.button_pressed = settings["vsync"]

func _connect_signals() -> void:
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	btn_back.pressed.connect(_back)

func _on_music_changed(v: float) -> void:
	settings["music"] = int(v)
	print("Música:", settings["music"])
	_apply_audio_bus_volume("Music", settings["music"])

func _on_sfx_changed(v: float) -> void:
	settings["sfx"] = int(v)
	print("SFX:", settings["sfx"])
	_apply_audio_bus_volume("SFX", settings["sfx"])

func _on_fullscreen_toggled(on: bool) -> void:
	settings["fullscreen"] = on
	print("Fullscreen:", on)
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(on: bool) -> void:
	settings["vsync"] = on
	print("VSync:", on)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED
	)

func _apply_audio_bus_volume(bus_name: String, percent: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		# Si no existen buses "Music" y "SFX", no rompemos nada.
		return

	var db := linear_to_db(clamp(percent / 100.0, 0.0, 1.0))
	AudioServer.set_bus_volume_db(idx, db)

func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
