shader_type canvas_item;
render_mode unshaded;


// Noise utilizado para formar as ondas.
uniform sampler2D flow_noise :
	repeat_enable,
	filter_nearest;


// Velocidade geral.
uniform float speed : hint_range(0.0, 2.0) = 0.20;


// Tamanho das formações.
uniform float scale : hint_range(0.001, 0.2) = 0.035;


// Quanto o padrão se deforma.
uniform float warp_strength : hint_range(0.0, 1.0) = 0.18;


// Tamanho lógico do pixel do efeito.
uniform float pixel_size : hint_range(1.0, 8.0) = 1.0;


// Cores.
uniform vec4 water_color : source_color =
	vec4(0.08, 0.42, 0.65, 1.0);

uniform vec4 wave_color : source_color =
	vec4(0.22, 0.62, 0.78, 1.0);


// Transparência geral.
uniform float opacity : hint_range(0.0, 1.0) = 0.55;


// Quantos detalhes claros aparecem.
uniform float wave_threshold :
	hint_range(0.0, 1.0) = 0.58;


varying vec2 world_pos;


void vertex() {
	world_pos =
		(MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {

	// Tile original = máscara.
	vec4 tile = texture(TEXTURE, UV);

	if (tile.a <= 0.0) {
		discard;
	}


	// ============================================
	// PIXELIZAÇÃO
	// ============================================

	vec2 p =
		floor(world_pos / pixel_size)
		* pixel_size;

	vec2 uv =
		p * scale;

	float t =
		TIME * speed;


	// ============================================
	// FLOW / DOMAIN WARP
	// ============================================

	// Movimento X.
	float flow_x =
		texture(
			flow_noise,
			uv * 0.60 +
			vec2(
				t * 0.21,
				t * 0.13
			)
		).r;


	// Movimento Y independente.
	float flow_y =
		texture(
			flow_noise,
			uv * 0.60 +
			vec2(
				0.53 - t * 0.17,
				0.27 + t * 0.23
			)
		).r;


	vec2 flow =
		vec2(flow_x, flow_y)
		* 2.0 - 1.0;


	// Deforma as coordenadas.
	vec2 warped_uv =
		uv +
		flow * warp_strength;


	// ============================================
	// SUPERFÍCIE
	// ============================================

	float wave_a =
		texture(
			flow_noise,
			warped_uv +
			vec2(
				t * 0.08,
				-t * 0.05
			)
		).r;


	float wave_b =
		texture(
			flow_noise,
			warped_uv * 1.65 +
			vec2(
				0.37 - t * 0.04,
				0.73 + t * 0.07
			)
		).r;


	float waves =
		wave_a * 0.65 +
		wave_b * 0.35;


	// ============================================
	// PIXEL ART
	// ============================================

	float wave_mask =
		step(
			wave_threshold,
			waves
		);


	vec3 final_color =
		mix(
			water_color.rgb,
			wave_color.rgb,
			wave_mask
		);


	// ============================================
	// TRANSPARÊNCIA
	// ============================================

	COLOR =
		vec4(
			final_color,
			opacity * tile.a
		);
}