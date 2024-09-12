shader_type canvas_item;
render_mode unshaded;

uniform sampler2D texture2;
uniform float mix_alpha;

varying vec2 uv2;

void vertex() {
	// Called for every vertex the material is visible on.
	uv2 = CUSTOM0.xy;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 t1Col = texture(TEXTURE, UV);
	vec4 t2Col = texture(texture2, uv2);
	COLOR= mix(t1Col, t2Col, mix_alpha);
	//COLOR = vec4(uv2.x, uv2.y, 0, 1);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
