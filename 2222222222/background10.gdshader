shader_type canvas_item;

uniform sampler2D texture1;
uniform sampler2D texture2;

void fragment() {
    float blend = smoothstep(0.2, 0.8, UV.x); // 부드러운 전환을 더 넓게
    vec4 color1 = texture(texture1, UV);
    vec4 color2 = texture(texture2, UV);
    COLOR = mix(color1, color2, blend);
}
