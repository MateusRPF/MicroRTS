shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float width : hint_range(0.0, 10.0) = 0; 
uniform bool add_diagonals = false;
// Higher value = more aggressive at removing outlines from gaps/holes
uniform float gap_suppression : hint_range(0.0, 1.0) = 1.0; 

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * width;
    vec4 original_color = texture(TEXTURE, UV);
    
    // 1. Calculate Outline Alpha using MAX instead of ADD
    // Using max() prevents the alpha from "stacking" and bloating in narrow gaps.
    float outline_alpha = 0.0;
    outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
    outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
    outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
    outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);

    if (add_diagonals) {
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(size.x, size.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-size.x, size.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(size.x, -size.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-size.x, -size.y)).a);
    }

    // 2. CONCAVE SUPPRESSION LOGIC
    // We sample a "blurred" version of the alpha (MIPMAP level 2.0 or 3.0).
    // If the blurred alpha is high, but our current pixel is empty, we are likely in a gap.
    float blurred_alpha = textureLod(TEXTURE, UV, 2.0).a;
    
    // If we are in a "crowded" transparent area, we suppress the outline alpha.
    float suppression_factor = smoothstep(gap_suppression, 1.0, blurred_alpha);
    outline_alpha -= suppression_factor;
    outline_alpha = clamp(outline_alpha, 0.0, outline_color.a);

    // 3. APPLY COLORS
    // We only want the outline to appear where the original sprite is transparent.
    vec4 final_color = mix(outline_color, original_color, original_color.a);
    
    // The final alpha is the original sprite OR the suppressed outline.
    float final_alpha = max(original_color.a, outline_alpha);
    
    COLOR = vec4(final_color.rgb, final_alpha);
}