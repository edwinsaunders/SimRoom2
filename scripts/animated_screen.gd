extends MeshInstance3D

const TEXTURE_WIDTH := 160
const TEXTURE_HEIGHT := 90
const PIXEL_SIZE := 4
const LOOP_SECONDS := 3.0

var _image: Image
var _texture: ImageTexture
var _palette := [
	Color8(0, 229, 255),
	Color8(255, 67, 208),
	Color8(111, 59, 255),
	Color8(147, 255, 0),
	Color8(0, 151, 255)
]


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(3.2, 1.8)
	mesh = quad

	_image = Image.create(TEXTURE_WIDTH, TEXTURE_HEIGHT, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.emission_enabled = true
	material.emission_texture = _texture
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 2.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material_override = material

	_draw_frame(0.0)
	_texture.update(_image)


func _process(_delta: float) -> void:
	var loop_t := fposmod(Time.get_ticks_msec() / 1000.0, LOOP_SECONDS) / LOOP_SECONDS
	_draw_frame(loop_t)
	_texture.update(_image)


func _draw_frame(loop_t: float) -> void:
	_image.fill(Color(0.015, 0.015, 0.035, 1.0))

	var grid_w := TEXTURE_WIDTH / PIXEL_SIZE
	var grid_h := TEXTURE_HEIGHT / PIXEL_SIZE

	for gy in range(grid_h):
		for gx in range(grid_w):
			var x_norm: float = float(gx) / float(grid_w - 1)
			var y_norm: float = float(gy) / float(max(grid_h - 1, 1))

			var traveling_wave: float = pow(max(0.0, sin(TAU * (loop_t - x_norm * 0.23 - float(gy % 3) * 0.024))), 3.0)
			var breathing_wave: float = 0.5 + 0.5 * sin(TAU * (loop_t + x_norm * 0.12 + y_norm * 0.18))
			var sparkle: float = pow(max(0.0, sin(TAU * (loop_t * 2.0 + x_norm * 0.35 + y_norm * 0.27))), 8.0)
			var energy: float = clamp(traveling_wave * 0.82 + breathing_wave * 0.22 + sparkle * 0.36, 0.0, 1.0)

			var palette_position: float = fposmod(x_norm * 2.7 + y_norm * 0.9 + loop_t * 2.2, float(_palette.size()))
			var i0 := int(floor(palette_position))
			var i1: int = (i0 + 1) % _palette.size()
			var blend: float = palette_position - floor(palette_position)
			var neon: Color = _palette[i0].lerp(_palette[i1], blend)

			var background := Color(0.02, 0.02, 0.045, 1.0)
			var cell_color: Color = background.lerp(neon, energy)

			if energy > 0.38:
				cell_color = cell_color.lightened(min(0.35, energy * 0.22))

			_fill_rect(gx * PIXEL_SIZE, gy * PIXEL_SIZE, PIXEL_SIZE, PIXEL_SIZE, cell_color)

	var accent_y := int((0.5 + 0.5 * sin(TAU * loop_t)) * float(TEXTURE_HEIGHT - PIXEL_SIZE * 2))
	_fill_rect(0, accent_y, TEXTURE_WIDTH, PIXEL_SIZE, Color(0.02, 0.04, 0.12, 1.0))


func _fill_rect(start_x: int, start_y: int, width: int, height: int, color: Color) -> void:
	for y in range(start_y, start_y + height):
		for x in range(start_x, start_x + width):
			_image.set_pixel(x, y, color)
