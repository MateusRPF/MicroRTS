shader_type canvas_item;

uniform vec2 grid_size = vec2(16.0, 16.0);
uniform float blur_radius = 1;
uniform float edge_falloff = 0.6;
uniform float max_alpha = 1;

float gaussian(float x, float sigma) {
    return exp(-0.5 * (x * x) / (sigma * sigma));
}

void fragment() {
    vec2 uv = UV;
    vec2 texel = 1.0 / grid_size;

    float center = texture(TEXTURE, uv).r;

    float sum = 0.0;
    float weight = 0.0;
    int radius = int(blur_radius);

    for (int x = -radius; x <= radius; x++) {
        for (int y = -radius; y <= radius; y++) {
            vec2 offset = vec2(float(x), float(y)) * texel;
            float w = gaussian(length(vec2(float(x), float(y))), blur_radius * 0.7);
            sum += texture(TEXTURE, clamp(uv + offset, vec2(0.0), vec2(1.0))).r * w;
            weight += w;
        }
    }

    float blur = sum / weight;
    float fade = smoothstep(0.0, edge_falloff, blur);
    float alpha = (1.0 - fade) * max_alpha;

    // Fully clear visible tiles and apply partial fog to seen tiles.
    if (center >= 1.0) {
        alpha = 0.0;
    } else if (center >= 0.5) {
        alpha = min(alpha, 0.5 * max_alpha);
    }

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}