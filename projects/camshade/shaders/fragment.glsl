// Developed by Aidan Fox


//  *** Socials ***
//
//  LinkedIn: www.linkedin.com/in/aidan-fox-460594270
//  GitHub: github.com/maybe-aidan
//  itch.io: maybeaidan.itch.io
//
//  Let me know what you think!

uniform sampler2D u_texture;
uniform float u_time;

varying vec2 v_uv;

void main(){
    vec2 uv = vec2(v_uv.x * -1.0 + 1.0, v_uv.y); // Mirrored UVs to make posing for a snapshot easier.
    // For non-mirrored:
    // uv = v_uv;
    vec3 color = texture2D(u_texture,uv).rgb;

    gl_FragColor = vec4(color, 1.0);
}