shader_type canvas_item;

uniform bool outline_enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_thickness : hint_range(0.0, 10.0) = 1.0;

uniform float shake_offset = 0.0;

void vertex() {
    VERTEX.x += shake_offset;
}

void fragment() {
    vec4 original = texture(TEXTURE, UV);

    if (!outline_enabled) {
        COLOR = original;
    } else {
        vec2 size = TEXTURE_PIXEL_SIZE * outline_thickness;

        if (original.a == 0.0) {
            float neighbor_alpha = 0.0;

            neighbor_alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
            neighbor_alpha += texture(TEXTURE, UV - vec2(size.x, 0.0)).a;
            neighbor_alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
            neighbor_alpha += texture(TEXTURE, UV - vec2(0.0, size.y)).a;

            if (neighbor_alpha > 0.0) {
                COLOR = outline_color;
            } else {
                discard;
            }
        } else {
            COLOR = original;
        }
    }
}