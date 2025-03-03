shader_type spatial;

uniform vec3 _BaseColor : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	vec3 view_normal = (vec4(NORMAL, 1.) * VIEW_MATRIX).xyz;
	
	//ALBEDO = mod(NORMAL.x, 1.) * _BaseColor;
	ALBEDO = view_normal;
	
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
