shader_type canvas_item;

uniform float time_offset : hint_range(0.0, 100.0) = 0.0;

void fragment() {
    vec2 uv = UV;
    float noise = sin(uv.x * 8.0 + time_offset) * cos(uv.y * 6.0 + time_offset * 0.7) * 0.5 + 0.5;
    float vignette = smoothstep(0.3, 1.0, length(uv - 0.5) * 1.8);
    float fog = mix(0.15, 0.55, noise) * vignette;
    COLOR = vec4(0.6, 0.0, 0.0, fog);
}