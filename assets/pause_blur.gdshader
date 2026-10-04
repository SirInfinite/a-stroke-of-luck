shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 4.0) = 2.2;
uniform vec4 dim_color : source_color = vec4(0.01, 0.025, 0.02, 0.58);

void fragment() {
	vec4 scene_color = textureLod(screen_texture, SCREEN_UV, blur_lod);
	COLOR = vec4(mix(scene_color.rgb, dim_color.rgb, dim_color.a), 1.0);
}
