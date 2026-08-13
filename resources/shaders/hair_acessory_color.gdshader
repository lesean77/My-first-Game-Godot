shader_type canvas_item;


// =========================================================
// CORES ESCOLHIDAS PELO PLAYER
// =========================================================

uniform vec4 hair_color : source_color = vec4(
	0.3647,
	0.1725,
	0.1569,
	1.0
);

uniform vec4 accessory_color : source_color = vec4(
	0.4941,
	0.5922,
	0.7922,
	1.0
);


const float COLOR_TOLERANCE = 0.015;


bool same_color(vec3 color_a, vec3 color_b) {
	return distance(color_a, color_b) < COLOR_TOLERANCE;
}


// Gera highlight misturando a cor com branco.
vec3 lighten_color(vec3 color, float amount) {
	return mix(
		color,
		vec3(1.0),
		amount
	);
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
	// ACCESSORY
	//
	// Os tons quase brancos funcionam como highlights.
	// #7E97CA é considerado a cor principal.
	// =====================================================


	// #F4F7F7
	// Highlight máximo.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.956863,
				0.968627,
				0.968627
			)
		)
	) {
		COLOR = vec4(
			lighten_color(
				accessory_color.rgb,
				0.70
			),
			tex.a
		);
	}


	// #DDE8E7
	// Highlight forte.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.866667,
				0.909804,
				0.905882
			)
		)
	) {
		COLOR = vec4(
			lighten_color(
				accessory_color.rgb,
				0.50
			),
			tex.a
		);
	}


	// #C6C9CD
	// Highlight médio.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.776471,
				0.788235,
				0.803922
			)
		)
	) {
		COLOR = vec4(
			lighten_color(
				accessory_color.rgb,
				0.30
			),
			tex.a
		);
	}


	// #999E9E
	// Highlight leve.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.600000,
				0.619608,
				0.619608
			)
		)
	) {
		COLOR = vec4(
			lighten_color(
				accessory_color.rgb,
				0.15
			),
			tex.a
		);
	}


	// #86A2D9
	// Tom claro da cor principal.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.525490,
				0.635294,
				0.850980
			)
		)
	) {
		COLOR = vec4(
			lighten_color(
				accessory_color.rgb,
				0.08
			),
			tex.a
		);
	}


	// #7E97CA
	// Cor principal escolhida.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.494118,
				0.592157,
				0.792157
			)
		)
	) {
		COLOR = vec4(
			accessory_color.rgb,
			tex.a
		);
	}


	// #7277B0
	// Sombra.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.447059,
				0.466667,
				0.690196
			)
		)
	) {
		COLOR = vec4(
			accessory_color.rgb * 0.65,
			tex.a
		);
	}


	// #565784
	// Sombra profunda.
	else if (
		same_color(
			tex.rgb,
			vec3(
				0.337255,
				0.341176,
				0.517647
			)
		)
	) {
		COLOR = vec4(
			accessory_color.rgb * 0.40,
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