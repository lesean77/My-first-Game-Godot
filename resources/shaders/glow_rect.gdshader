shader_type canvas_item;
render_mode unshaded;


// =====================================================
// COR PRINCIPAL
// =====================================================

uniform vec4 glow_color : source_color = vec4(
	0.25,
	1.0,
	0.20,
	1.0
);


// =====================================================
// INTENSIDADE DO GLOW EXTERNO
// =====================================================

uniform float glow_strength : hint_range(
	0.0,
	1.0
) = 0.55;


// =====================================================
// ESPALHAMENTO DO GLOW
// =====================================================

uniform float glow_radius : hint_range(
	1.0,
	10.0
) = 3.0;


// =====================================================
// FADE NAS BORDAS DO CANVAS
//
// Faz o glow desaparecer antes de chegar
// às extremidades do ColorRect.
// =====================================================

uniform float canvas_edge_fade : hint_range(
	1.0,
	20.0
) = 6.0;


// =====================================================
// INTENSIDADE DA COR NO CENTRO
//
// 0.0 = centro totalmente transparente
// 0.10 = cor bem leve
// 0.20 = cor mais perceptível
// =====================================================

uniform float center_strength : hint_range(
	0.0,
	1.0
) = 0.10;


// =====================================================
// TAMANHO DO GLOWRECT
//
// Exemplo:
// GlowRect = 230 x 42
// =====================================================

uniform vec2 canvas_size = vec2(
	230.0,
	42.0
);


// =====================================================
// TAMANHO DA ÁREA INTERNA
//
// NinePatchRect = 202 x 14
// =====================================================

uniform vec2 inner_size = vec2(
	202.0,
	14.0
);


// =====================================================
// DISTÂNCIA RETANGULAR
//
// max() mantém o formato retangular,
// sem arredondar os cantos.
// =====================================================

float rectangle_distance(
	vec2 position,
	vec2 half_size
) {
	vec2 distance_axis = (
		abs(position)
		- half_size
	);
	
	return max(
		distance_axis.x,
		distance_axis.y
	);
}


// =====================================================
// FRAGMENT
// =====================================================

void fragment() {
	// -------------------------------------------------
	// Converte UV para coordenadas em pixels
	// -------------------------------------------------
	
	vec2 position = (
		UV - vec2(0.5)
	) * canvas_size;
	
	
	vec2 half_inner_size = (
		inner_size * 0.5
	);
	
	
	vec2 half_canvas_size = (
		canvas_size * 0.5
	);
	
	
	// -------------------------------------------------
	// Distância até a área interna 202x14
	// -------------------------------------------------
	
	float distance_to_rectangle = (
		rectangle_distance(
			position,
			half_inner_size
		)
	);
	
	
	// -------------------------------------------------
	// Máscara externa
	//
	// 0 = dentro da barra
	// 1 = fora da barra
	// -------------------------------------------------
	
	float outside_mask = step(
		0.0,
		distance_to_rectangle
	);
	
	
	// -------------------------------------------------
	// Máscara interna
	//
	// 1 = dentro da barra
	// 0 = fora
	// -------------------------------------------------
	
	float inside_mask = (
		1.0 - outside_mask
	);
	
	
	// =================================================
	// GLOW EXTERNO
	// =================================================
	
	float glow = exp(
		-max(
			distance_to_rectangle,
			0.0
		)
		/ glow_radius
	);
	
	
	glow *= outside_mask;
	
	
	// =================================================
	// FADE NAS BORDAS DO GLOWRECT
	//
	// Impede aparecer aquele retângulo externo
	// correspondente ao limite do canvas.
	// =================================================
	
	vec2 distance_to_canvas_edge = (
		half_canvas_size
		- abs(position)
	);
	
	
	float nearest_canvas_edge = min(
		distance_to_canvas_edge.x,
		distance_to_canvas_edge.y
	);
	
	
	float canvas_fade = smoothstep(
		0.0,
		canvas_edge_fade,
		nearest_canvas_edge
	);
	
	
	glow *= canvas_fade;
	glow *= glow_strength;
	
	
	// =================================================
	// COR INTERNA
	//
	// Aplica uma pequena quantidade de glow_color
	// dentro dos 202x14.
	// =================================================
	
	float center_alpha = (
		inside_mask
		* center_strength
		* glow_color.a
	);
	
	
	// =================================================
	// RESULTADO FINAL
	//
	// Fora:
	// usa glow.
	//
	// Dentro:
	// usa center_strength.
	// =================================================
	
	float final_alpha = max(
		glow * glow_color.a,
		center_alpha
	);
	
	
	COLOR = vec4(
		glow_color.rgb,
		final_alpha
	);
}