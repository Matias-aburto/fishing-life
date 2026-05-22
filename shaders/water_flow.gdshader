shader_type canvas_item;

uniform float flow_speed : hint_range(0.0, 2.0) = 0.45;
uniform float wave_strength : hint_range(0.0, 0.2) = 0.06;
uniform float band_strength : hint_range(0.0, 0.15) = 0.04;

varying vec2 world_pos;


void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	vec3 base_rgb = COLOR.rgb;
	float t = TIME;

	float ripple = sin(world_pos.x * 0.14 + world_pos.y * 0.05 + t * flow_speed * 3.0);
	ripple += sin(world_pos.x * 0.09 - world_pos.y * 0.07 + t * flow_speed * 2.0) * 0.6;
	ripple *= 0.5;

	float bands = sin(world_pos.y * 0.12 - t * flow_speed * 4.0 + world_pos.x * 0.03);
	bands = smoothstep(0.62, 1.0, bands * 0.5 + 0.5);

	vec3 highlight = vec3(0.92, 0.98, 1.0);
	base_rgb = mix(base_rgb, highlight, ripple * wave_strength + bands * band_strength);

	COLOR = vec4(base_rgb, COLOR.a);
}
