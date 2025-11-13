shader_type canvas_item;

// Esto captura la pantalla del juego
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

// Este es el parámetro que controlas en la animación (0 = sin blur, 5 = blur máximo)
uniform float lod : hint_range(0.0, 5) = 0.0;

void fragment() {
    // 1. Obtiene el píxel borroso de la pantalla
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
    
    // 2. Oscurece el píxel y le da opacidad
    // Multiplica el color borroso por un gris oscuro (0.2) y lo hace 50% transparente (0.5)
    // ¡Puedes cambiar vec4(0.2, 0.2, 0.2, 0.5) para ajustar qué tan oscuro lo quieres!
    COLOR = color * vec4(0.2, 0.2, 0.2, 0.5);
}
