shader_type canvas_item;

#define PI 3.14159

void fragment() {
    // Resolution
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;

    // Equivalent of fragCoord
    vec2 fragCoord = UV * resolution;

    // Original Shadertoy math
    vec2 uvIni = (2.0 * fragCoord - resolution) / resolution.y;
    vec2 uv = vec2(
        length(uvIni),
        (atan(uvIni.y, uvIni.x) + PI) * 0.5 / PI
    );

    float size = uv.x / 0.5 + 0.2;
    float time = TIME * 0.5;

    float checkerBoard = mod(
        floor(uv.x * 120.0 / size + time) +
        floor(20.0 * uv.y + time + 4.0 * uv.x),
        2.0
    );

    // Blue checkerboard colors
    vec3 color = (checkerBoard > 0.0)
        ? vec3(0.2, 0.45, 0.8)
        : vec3(0.4, 0.65, 1.0);

    // Center blur
    color *= smoothstep(0.0, 0.5, uv.x);

    // Outer glow
    color += smoothstep(0.8, 2.2, uv.x);

    color = clamp(color, vec3(0.0), vec3(1.0));

    // Bright edge highlight
    color += smoothstep(1.1, 1.8, uv.x) *
             (vec3(0.7, 0.9, 1.0) - color);

    COLOR = vec4(color, 1.0);
}
