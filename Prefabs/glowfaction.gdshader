shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.001, 0.5) = 0.15;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.2;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform float pulse_amount : hint_range(0.0, 0.3) = 0.08;

void fragment() {
    vec2 center = vec2(0.5);
    float dist = distance(UV, center);

    // Time-based pulse
    float pulse = sin(TIME * pulse_speed) * pulse_amount;
    float dynamic_radius = radius + pulse;

    // Soft circular mask
    float circle = smoothstep(dynamic_radius, dynamic_radius - softness, dist);

    // Glow falloff
    float glow = pow(1.0 - dist / dynamic_radius, 2.0) * glow_strength;

    // Use the ColorRect's existing color
    vec4 base_color = COLOR;

    float alpha = circle * glow * base_color.a;

    COLOR = vec4(base_color.rgb * glow, alpha);
}