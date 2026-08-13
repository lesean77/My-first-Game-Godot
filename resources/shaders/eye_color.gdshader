shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(
	0.298039,
	0.709804,
	0.156863,
	1.0
);

const float COLOR_TOLERANCE = 0.015;

// #4CB528
const vec3 EYE_MAIN = vec3(
	0.298039,
	0.709804,
	0.156863
);

// #338816
const vec3 EYE_DARK = vec3(
	0.200000,
	0.533333,
	0.086275
);

// Quanto menor, mais escuro fica.
const float DARK_FACTOR = 0.45;

bool same_color(vec3 color_a, vec3 color_b) {
	return distance(color_a, color_b) < COLOR_TOLERANCE;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a <= 0.001) {
		COLOR = tex;
	}
	else if (
		same_color(
			tex.rgb,
			EYE_MAIN
		)
	) {
		COLOR = vec4(
			target_color.rgb,
			tex.a
		);
	}
	else if (
		same_color(
			tex.rgb,
			EYE_DARK
		)
	) {
		COLOR = vec4(
			target_color.rgb * DARK_FACTOR,
			tex.a
		);
	}
	else {
		COLOR = tex;
	}
}