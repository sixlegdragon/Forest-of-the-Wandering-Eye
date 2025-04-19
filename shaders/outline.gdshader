shader_type spatial;

#include "Helpers.gdshaderinc"

render_mode unshaded;
render_mode cull_disabled;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;

uniform sampler2D screen_overlay;

uniform vec3 outline_color : source_color;

uniform vec2 squiggle_time_modifier = vec2(1., 10.);
uniform vec2 squiggle_uv_stretch = vec2(10., 2.);
uniform float squiggle_intensity = .0001;

uniform float normal_sobel_offset = .01;
uniform float normal_thresh = .01;

uniform float depth_sobel_offset = .01;
uniform float depth_thresh = .01;

uniform float color_sobel_offset = .01;
uniform float color_thresh = .01;

//Comments moved to the top because of annoying reasons
//top left is (0,0) -> (1,0) or (-,-) -> (+,-)
//			  (0,1) -> (1,1) 	(-,+) -> (+,+)
//here we are going to calulate the roberts cross derivitive
//here is some usefull info https://homepages.inf.ed.ac.uk/rbf/HIPR2/roberts.htm
//Preprocessor directive so I dont need to define different functions for each sample -_-
#define ROBERT_CROSS_DEFINE(roberCrossName) \
float roberCrossName(in sampler2D tex, in vec2 uv, in vec2 roberts_cross_offset, in float thresh){ \
	roberts_cross_offset *= .001; \
	vec3 tl = texture(tex, uv + vec2(-roberts_cross_offset.x, -roberts_cross_offset.y)).rgb; \
	vec3 tr = texture(tex, uv + vec2(roberts_cross_offset.x, -roberts_cross_offset.y)).rgb; \
	vec3 bl = texture(tex, uv + vec2(-roberts_cross_offset.x, roberts_cross_offset.y)).rgb; \
	vec3 br = texture(tex, uv + vec2(roberts_cross_offset.x, roberts_cross_offset.y)).rgb; \
	vec3 cross1 = tl - br; \
	vec3 cross2 = tl - br; \
	float differential = sqrt(dot(cross1, cross1) + dot(cross2, cross2)); \
	differential = differential > thresh * .001 ? 1. : 0.; \
	return differential; \
}

//[p0, p1, p2] -> [(-,-) | (0,-) | (+,-)]
//[p3, na, p4] -> [(-,0) | (n/a) | (+,0)]
//[p5, p6, p7] -> [(-,+) | (0,+) | (+,+)]
//The for loop is fine cause the compiler with just unwrap the loops anyways
#define SOBEL_DEFINE(sobelName) \
float sobelName(in sampler2D tex, in vec2 uv, in vec2 sobel_offset, in float thresh){ \
	sobel_offset *= .001; \
	mat3 kernel_x = mat3( \
		vec3(1., 0., -1), \
		vec3(2., 0., -2), \
		vec3(1., 0., -1)); \
	mat3 kernel_y = mat3( \
		vec3( 1.,  2.,  1.), \
		vec3( 0.,  0.,  0.), \
		vec3(-1., -2., -1.)); \
	vec3 sobel_x = vec3(0.); \
	vec3 sobel_y = vec3(0.); \
	for(int x = -1; x < 2; x++){ \
	    for(int y = -1; y < 2; y++){ \
			vec3 tex = texture(tex, uv + vec2(sobel_offset.x * float(x), sobel_offset.y * float(y))).rgb; \
			sobel_x += tex * kernel_x[x + 1][y + 1]; \
			sobel_y += tex * kernel_y[x + 1][y + 1]; \
	    } \
	 } \
	float differential = sqrt(dot(sobel_x,sobel_x) + dot(sobel_y,sobel_y)); \
	differential = differential > thresh * .001 ? 1. : 0.; \
	return differential; \
}

void vertex() {
	POSITION = vec4(2. * VERTEX.xy, 1.0, 1.0);
}

SOBEL_DEFINE(sobelNormal)
SOBEL_DEFINE(sobelDepth)
SOBEL_DEFINE(sobelColor)

void fragment() {
	float normal_outline = 0.;
	float depth_outline  = 0.;
	float color_outline  = 0.;
	vec2 aspect_modifier = vec2(0.);
	if(VIEWPORT_SIZE.x > VIEWPORT_SIZE.y){
		//we are wide [ ----- ]
		aspect_modifier = vec2(1., float(VIEWPORT_SIZE.x) / float(VIEWPORT_SIZE.y));
	} else {
		//we are tall [|]
		aspect_modifier = vec2(float(VIEWPORT_SIZE.y) / float(VIEWPORT_SIZE.x), 1.);
	}
	vec2 timeModifier = vec2(squiggle_time_modifier.x * sin(TIME), TIME*squiggle_time_modifier.y);
	float displacementNoise = snoise(squiggle_uv_stretch * SCREEN_UV + timeModifier) * texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec2 modifiedUV = SCREEN_UV + .25 * pow(squiggle_intensity, 2) * displacementNoise;


	normal_outline = sobelNormal(NORMAL_TEXTURE, modifiedUV, aspect_modifier * normal_sobel_offset, normal_thresh);
	depth_outline = sobelDepth(DEPTH_TEXTURE, modifiedUV, aspect_modifier * depth_sobel_offset, depth_thresh);
	color_outline = sobelColor(SCREEN_TEXTURE, modifiedUV, aspect_modifier * color_sobel_offset, color_thresh);

	float combined_outline = max(max(normal_outline, depth_outline), color_outline);


	//ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).xyz;
	//ALBEDO = vec3(noise(SCREEN_UV * 5.));
	ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).xyz;
	//this is so darn silly lmao
	vec3 colored_outline = ALBEDO * combined_outline;
	ALBEDO = ALBEDO * (1.-vec3(combined_outline));
	ALBEDO += colored_outline * outline_color;
	//vec3 overlay_color = texture(screen_overlay, SCREEN_UV * 2.).xyz;
	//ALBEDO *= overlay_color * overlay_color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
