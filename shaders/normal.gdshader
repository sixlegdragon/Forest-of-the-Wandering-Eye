shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;

uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;


void vertex() { POSITION = vec4(2. * VERTEX.xy, 1.0, 1.0); }

void fragment() {
	ALBEDO = (texture(NORMAL_TEXTURE, SCREEN_UV)).xyz;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
