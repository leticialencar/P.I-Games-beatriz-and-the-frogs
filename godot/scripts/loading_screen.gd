extends Control

const DURATION := 8.0
const MESSAGE_DELAY := 2.5
const FROG_FRAME_DURATION := 0.15
const FROG_SCALE := 0.35

var messages := [
	"Beatriz vai com ou sem falta porque ela não perde um bingo.",
	"Beatriz é formada em arquitetura no The Sims 4.",
	"Não, Igor. Letícia não vai raspar o cabelo nem arrancar as unhas para jogar.",
	"Lembrete: Lucas é PJ. Para ele, 10h da manhã ainda é cedo.",
	"Curiosidade: o menor sapo conhecido cabe na ponta de um dedo.",
	"\"A gente não vai usar uma bazuca pra matar uma formiga.\" — Alexsandro, 2026",
	"Vem pro São João da FAP, Beatriz.",
	"Fabrício, por favor, traga o esparadrapo.",
	"Será que o mouse de Igor desconectou de novo?",
	"Lucas está trabalhando. É sério.",
	"Será que o Fabrício trouxe o esparadrapo?",
	"Simpatia: onde Igor quase secou a maionese temperada.",
	"Tadeu já foi revivido hoje?",
	"Curiosidade: Igor trocou de curso, mas o PI de Engenharia foi atrás dele.",
	"Será que a AraujoSat está funcionando hoje?",
	"Ramon é o professor favorito de Igor, Lucas e Beatriz.",
	"Não existe crise financeira que impeça uma Bulldog.",
	"Você sabia? Tadeu possui três netas: Evelyn, Beatriz e Letícia.",
	"Curiosidade: o \"vou já\" do Gabriel pode durar até duas horas.",
	"Você sabia? A virada de 2026 para 2027 vai ser six seven.",
]

@onready var message_label: Label = $MessageLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var frog_sprite: Sprite2D = $FrogSprite

var available_messages: Array = []
var message_timer := 0.0
var elapsed := 0.0
var frog_textures: Array[Texture2D] = []
var frog_frame := 0
var frog_timer := 0.0


func _ready() -> void:
	available_messages = messages.duplicate()
	available_messages.shuffle()
	_show_next_message()
	_load_frog_walk()
	if frog_textures.size() > 0:
		frog_sprite.texture = frog_textures[0]


func _process(delta: float) -> void:
	elapsed += delta
	progress_bar.value = clampf(elapsed / DURATION * 100.0, 0.0, 100.0)

	message_timer += delta
	if message_timer >= MESSAGE_DELAY:
		message_timer = 0.0
		_show_next_message()

	if frog_textures.size() > 0:
		frog_timer += delta
		if frog_timer >= FROG_FRAME_DURATION:
			frog_timer = 0.0
			frog_frame = (frog_frame + 1) % frog_textures.size()
			frog_sprite.texture = frog_textures[frog_frame]

	if elapsed >= DURATION:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _show_next_message() -> void:
	if available_messages.is_empty():
		available_messages = messages.duplicate()
		available_messages.shuffle()
	message_label.text = available_messages.pop_back()


func _load_frog_walk() -> void:
	var sheet := load("res://assets/frog/frog_spritesheet.png") as Texture2D
	var walk_rects := [
		Rect2(65, 424, 198, 176),
		Rect2(308, 424, 204, 173),
		Rect2(547, 424, 204, 176),
		Rect2(802, 429, 196, 171),
		Rect2(1046, 428, 200, 173),
		Rect2(1281, 428, 206, 169),
	]

	for region in walk_rects:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = region
		var image := atlas.get_image()
		var width := maxi(1, int(image.get_width() * FROG_SCALE))
		var height := maxi(1, int(image.get_height() * FROG_SCALE))
		image.resize(width, height, Image.INTERPOLATE_NEAREST)
		frog_textures.append(ImageTexture.create_from_image(image))
