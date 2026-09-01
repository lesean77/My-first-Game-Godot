shader_type canvas_item;


// =========================================================
// COR ESCOLHIDA PELO PLAYER
// =========================================================

uniform vec4 hair_color : source_color = vec4(
	0.3647,
	0.1725,
	0.1569,
	1.0
);


const float COLOR_TOLERANCE = 0.015;


bool same_color(vec3 color_a, vec3 color_b) {
	return distance(color_a, color_b) < COLOR_TOLERANCE;
}


void fragment() {
	vec4 tex = texture(TEXTURE, UV);


	// =====================================================
	// TRANSPARÊNCIA
	// =====================================================

	if (tex.a <= 0.001) {
		COLOR = tex;
	}


	// =====================================================
	// SOMBRA FIXA SOBRE A PELE
	// #3C0E24
	//
	// Mantém RGB e Alpha originais.
	// =====================================================

	else if (
		same_color(
			tex.rgb,
			vec3(
				0.235294,
				0.054902,
				0.141176
			)
		)
	) {
		COLOR = tex;
	}


	// =====================================================
	// HAIR
	// =====================================================


	// #FEFEFE
	// Tom 1 - mais claro.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.996078,
				0.996078,
				0.996078
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb,
			tex.a
		);
	}


	// #D9D9D9
	// Tom 2.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.850980,
				0.850980,
				0.850980
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb * 0.854,
			tex.a
		);
	}


	// #A5A5A5
	// Tom 3.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.647059,
				0.647059,
				0.647059
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb * 0.650,
			tex.a
		);
	}


	// #6E6E6E
	// Tom 4.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.431373,
				0.431373,
				0.431373
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb * 0.433,
			tex.a
		);
	}


	// #4A4A4A
	// Tom 5.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.290196,
				0.290196,
				0.290196
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb * 0.291,
			tex.a
		);
	}


	// #3C3B3C
	// Tom 6.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.235294,
				0.231373,
				0.235294
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb * 0.235,
			tex.a
		);
	}


	// #333233
	// Tom 7.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.200000,
				0.196078,
				0.200000
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb * 0.200,
			tex.a
		);
	}


	// #292829
	// Tom 8 - mais escuro.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.160784,
				0.156863,
				0.160784
			)
		)
	) {
		COLOR = vec4(
			hair_color.rgb * 0.160,
			tex.a
		);
	}


	// =====================================================
	// QUALQUER OUTRA COR
	//
	// Incluindo agora todos os acessórios:
	// mantém exatamente a cor original da textura.
	// =====================================================

	else {
		COLOR = tex;
	}
}