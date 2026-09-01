shader_type particles;


// =====================================================
// WATER SPLASH
// =====================================================

uniform vec4 water_color : source_color = vec4(
	0.45,
	0.82,
	1.0,
	1.0
);


// 1.0  = direita
// -1.0 = esquerda
uniform float splash_direction = 1.0;


// Velocidade lateral dominante.
uniform float horizontal_speed_min = 18.0;
uniform float horizontal_speed_max = 38.0;


// Altura normal das gotas.
// Bem menor que antes para não parecer uma fonte.
uniform float upward_speed_min = 4.0;
uniform float upward_speed_max = 13.0;


// Algumas gotas podem subir mais.
uniform float high_drop_chance = 0.22;

uniform float high_upward_speed_min = 14.0;
uniform float high_upward_speed_max = 23.0;


// Gravidade.
uniform float gravity = 65.0;


// Área pequena ao redor da boia.
uniform float spawn_radius_x = 3.0;
uniform float spawn_radius_y = 1.5;


// Escala das gotas.
uniform float min_scale = 0.8;
uniform float max_scale = 1.5;


// =====================================================
// RANDOM
// =====================================================

float rand_from_seed(uint seed) {
	seed = seed * 747796405u + 2891336453u;

	seed = (
		(
			seed
			>> (
				(seed >> 28u)
				+ 4u
			)
		)
		^ seed
	) * 277803737u;

	seed = (
		seed >> 22u
	) ^ seed;

	return (
		float(seed)
		/ 4294967295.0
	);
}


float random_value(
	uint seed,
	uint offset
) {
	return rand_from_seed(
		seed
		+ offset * 1013u
	);
}


// =====================================================
// START
// =====================================================

void start() {
	float spawn_random_x = (
		random_value(
			RANDOM_SEED,
			1u
		)
		* 2.0
		- 1.0
	);


	float spawn_random_y = (
		random_value(
			RANDOM_SEED,
			2u
		)
		* 2.0
		- 1.0
	);


	float horizontal_random = random_value(
		RANDOM_SEED,
		3u
	);


	float vertical_random = random_value(
		RANDOM_SEED,
		4u
	);


	float height_type = random_value(
		RANDOM_SEED,
		5u
	);


	float scale_random = random_value(
		RANDOM_SEED,
		6u
	);


	// =================================================
	// POSIÇÃO INICIAL
	// =================================================

	if (RESTART_POSITION) {
		TRANSFORM = EMISSION_TRANSFORM;
	}


	TRANSFORM[3].x += (
		spawn_random_x
		* spawn_radius_x
	);


	TRANSFORM[3].y += (
		spawn_random_y
		* spawn_radius_y
	);


	// =================================================
	// VELOCIDADE
	// =================================================

	if (RESTART_VELOCITY) {
		float horizontal_speed = mix(
			horizontal_speed_min,
			horizontal_speed_max,
			horizontal_random
		);


		float upward_speed;


		// Algumas gotas maiores sobem mais.
		if (height_type < high_drop_chance) {
			upward_speed = mix(
				high_upward_speed_min,
				high_upward_speed_max,
				vertical_random
			);


			// Gotas altas avançam um pouco menos.
			horizontal_speed *= 0.70;
		}

		else {
			upward_speed = mix(
				upward_speed_min,
				upward_speed_max,
				vertical_random
			);
		}


		VELOCITY = vec3(
			horizontal_speed
			* splash_direction,

			-upward_speed,

			0.0
		);
	}


	// =================================================
	// ESCALA
	// =================================================

	if (RESTART_ROT_SCALE) {
		float particle_scale = mix(
			min_scale,
			max_scale,
			scale_random
		);


		TRANSFORM[0].x *= particle_scale;
		TRANSFORM[1].y *= particle_scale;
	}


	// =================================================
	// COR
	// =================================================

	if (RESTART_COLOR) {
		COLOR = water_color;
	}


	if (RESTART_CUSTOM) {
		CUSTOM.x = 0.0;
	}
}


// =====================================================
// PROCESS
// =====================================================

void process() {
	// Gravidade.
	VELOCITY.y += (
		gravity
		* DELTA
	);


	// Movimento.
	TRANSFORM[3].xyz += (
		VELOCITY
		* DELTA
	);


	// Idade normalizada.
	CUSTOM.x += (
		DELTA
		/ LIFETIME
	);


	float age = clamp(
		CUSTOM.x,
		0.0,
		1.0
	);


	// =================================================
	// FADE
	//
	// Mantém a gota bem visível no início e
	// desaparece rapidamente perto do final.
	// =================================================

	float alpha = (
		1.0
		- smoothstep(
			0.55,
			1.0,
			age
		)
	);


	COLOR = vec4(
		water_color.rgb,
		water_color.a
		* alpha
	);
}