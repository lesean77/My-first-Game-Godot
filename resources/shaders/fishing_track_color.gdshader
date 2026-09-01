shader_type canvas_item;
render_mode unshaded;


uniform vec4 status_color : source_color = vec4(
	0.25,
	1.0,
	0.20,
	1.0
);


const vec3 OUTLINE_COLOR = vec3(
	61.0 / 255.0,
	61.0 / 255.0,
	61.0 / 255.0
);


const float INNER_ALPHA = 77.0 / 255.0;


uniform float color_tolerance : hint_range(
	0.001,
	0.1
) = 0.025;


uniform float alpha_tolerance : hint_range(
	0.001,
	0.1
) = 0.025;


void fragment() {
	vec4 source = texture(
		TEXTURE,
		UV
	);
	
	vec4 result = source;
	
	
	// -----------------------------------------
	// #3D3D3D
	// -----------------------------------------
	
	bool is_outline = (
		distance(
			source.rgb,
			OUTLINE_COLOR
		)
		<= color_tolerance
		&& source.a > 0.90
	);
	
	
	// -----------------------------------------
	// #000000 com alpha 77
	// 77 / 255 = 0.30196
	// -----------------------------------------
	
	bool is_inner = (
		distance(
			source.rgb,
			vec3(0.0)
		)
		<= color_tolerance
		&& abs(
			source.a - INNER_ALPHA
		)
		<= alpha_tolerance
	);
	
	
	if (is_outline) {
			result.rgb = status_color.rgb;
	}
	
	
	
	if (is_inner) {
		result.rgb = status_color.rgb;
		
		// Mantém exatamente o alpha
		// que já estava no pixel.
		result.a = source.a;
	}
	
	
	COLOR = result;
}