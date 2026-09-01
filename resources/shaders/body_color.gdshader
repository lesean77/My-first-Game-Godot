shader_type canvas_item;


// =========================================================
// COR ESCOLHIDA PELO PLAYER
// =========================================================

uniform vec4 skin_color : source_color = vec4(
	0.850980,
	0.627451,
	0.400000,
	1.0
);


// =========================================================
// CONFIGURAÇÃO
// =========================================================

const float COLOR_TOLERANCE = 0.015;


// =========================================================
// CORES ORIGINAIS DO BODY
// =========================================================

// #D9A066
// Cor principal.
const vec3 SKIN_MAIN = vec3(
	0.850980,
	0.627451,
	0.400000
);


// #B76C42
// Sombra leve.
const vec3 SKIN_LIGHT_SHADOW = vec3(
	0.717647,
	0.423529,
	0.258824
);


// #883C25
// Sombra pesada.
const vec3 SKIN_HEAVY_SHADOW = vec3(
	0.533333,
	0.235294,
	0.145098
);


// =========================================================
// RELAÇÃO ENTRE OS TONS
//
// Calculado a partir da paleta original:
//
// #D9A066 -> #B76C42
// #D9A066 -> #883C25
//
// Utilizamos fatores RGB separados para preservar o
// aspecto quente das sombras da pele.
// =========================================================

const vec3 LIGHT_SHADOW_FACTOR = vec3(
	0.843318,
	0.675000,
	0.647059
);

const vec3 HEAVY_SHADOW_FACTOR = vec3(
	0.626728,
	0.375000,
	0.362745
);


// =========================================================
// COMPARAÇÃO DE COR
// =========================================================

bool same_color(vec3 color_a, vec3 color_b) {
	return distance(color_a, color_b) < COLOR_TOLERANCE;
}


// =========================================================
// FRAGMENT
// =========================================================

void fragment() {
	vec4 tex = texture(TEXTURE, UV);


	// Transparência
	if (tex.a <= 0.001) {
		COLOR = tex;
	}


	// =====================================================
	// COR PRINCIPAL
	// #D9A066
	// =====================================================

	else if (
		same_color(
			tex.rgb,
			SKIN_MAIN
		)
	) {
		COLOR = vec4(
			skin_color.rgb,
			tex.a
		);
	}


	// =====================================================
	// SOMBRA LEVE
	// #B76C42
	// =====================================================

	else if (
		same_color(
			tex.rgb,
			SKIN_LIGHT_SHADOW
		)
	) {
		COLOR = vec4(
			skin_color.rgb * LIGHT_SHADOW_FACTOR,
			tex.a
		);
	}


	// =====================================================
	// SOMBRA PESADA
	// #883C25
	// =====================================================

	else if (
		same_color(
			tex.rgb,
			SKIN_HEAVY_SHADOW
		)
	) {
		COLOR = vec4(
			skin_color.rgb * HEAVY_SHADOW_FACTOR,
			tex.a
		);
	}


	// =====================================================
	// QUALQUER OUTRA COR
	// =====================================================

	else {
		COLOR = tex;
	}
}