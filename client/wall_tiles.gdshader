shader_type canvas_item;
uniform vec2 repeats = vec2(1.0);
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	float frame = mod(floor(TIME * 3.0), 4.0);
	vec2 cell = fract(UV * repeats);
	COLOR = texture(TEXTURE, vec2((cell.x + frame) / 4.0, cell.y)) * tint;
}
