shader_type canvas_item;

// Exposes these variables to the Godot Inspector
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 0.2); // Default: White
uniform float width : hint_range(0.0, 10.0) = 0.5; 
uniform bool add_diagonals = false; // True for a rounder 'sticker' look, False for a blockier retro look

void fragment() {
    // TEXTURE_PIXEL_SIZE gives us the exact size of 1 pixel in UV coordinates
    vec2 size = TEXTURE_PIXEL_SIZE * width;
    
    // Sample the color and alpha of the original sprite at the current pixel
    vec4 original_color = texture(TEXTURE, UV);

    float outline_alpha = 0.0;

    // Look at the 4 neighboring pixels (Up, Down, Left, Right)
    outline_alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    outline_alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    outline_alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    outline_alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;

    // Look at the 4 diagonal neighbors for a thicker, filled-in outline
    if (add_diagonals) {
        outline_alpha += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
        outline_alpha += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
        outline_alpha += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
        outline_alpha += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    }

    // Ensure the alpha doesn't stack past 1.0 (fully opaque)
    outline_alpha = min(outline_alpha, 1.0);

    // If the original pixel has color, keep it. If it's transparent, use the outline color.
    vec4 final_color = mix(outline_color, original_color, original_color.a);

    // Apply the final color, using the highest alpha between the sprite and the outline
    COLOR = vec4(final_color.rgb, max(original_color.a, outline_alpha));
}