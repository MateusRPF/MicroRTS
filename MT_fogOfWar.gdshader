shader_type canvas_item;

uniform vec2 grid_size = vec2(0.5, 0.5);
uniform float softness = 1.0;
uniform float max_alpha = 1;

void fragment() {
    vec2 uv = UV;
    vec2 delta = 1.0 / grid_size;

    float sum = 0.0;
    int samples = 0;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * delta;
            sum += texture(TEXTURE, clamp(uv + offset, vec2(0.0), vec2(1.0))).r;
            samples++;
        }
    }

    float blur = sum / float(samples);
    float center = texture(TEXTURE, uv).r;
    float visibility = smoothstep(softness, 1.0 - softness, blur);
    float alpha = (1.0 - visibility) * max_alpha;
    if (center > 0.5) {
        alpha = 0.0;
    }

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}