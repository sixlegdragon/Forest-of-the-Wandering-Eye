shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;

#include "Helpers.gdshaderinc"

uniform sampler2D overlay_texture;


void vertex() { POSITION = vec4(2. * VERTEX.xy, 1.0, 1.0); }

void fragment() {
	vec2 timeModifier = vec2(0., TIME*50.);
	vec2 uvStretch = vec2(10., 1.);
	float diisplacementNoise = snoise(uvStretch * SCREEN_UV + timeModifier);
	ALBEDO = vec3(diisplacementNoise);
	//ALBEDO = vec3(SCREEN_UV + snoise(SCREEN_UV + TIME*5.), 0.);
	//ALBEDO = vec3(snoise(SCREEN_UV + TIME));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
