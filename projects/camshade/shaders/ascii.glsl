uniform sampler2D u_texture;
uniform sampler2D u_font;
uniform sampler2D u_noise;

uniform vec2 u_resolution;
uniform float u_time;

varying vec2 v_uv;

const float edge_pixel_size = 0.004;

vec3 edgeDetection(vec2 uv){
    // Sobel Kernels
    mat3 sobelX = mat3(-1.0, -2.0, -1.0,
                       0.0,  0.0, 0.0,
                       1.0,  2.0,  1.0);
    mat3 sobelY = mat3(-1.0,  0.0,  1.0,
                       -2.0,  0.0, 2.0,
                       -1.0,  0.0,  1.0);

    float sumX = 0.0; // X axis change
    float sumY = 0.0; // Y axis change

    for(int i = -1; i <= 1; i++){
        for(int j = -1; j <= 1; j++){
            vec2 offset = vec2(i, j) / u_resolution;

            vec3 texColor = texture2D(u_texture, uv + offset).xyz;

            sumX += length(texColor) * float(sobelX[1+i][1+j]);
            sumY += length(texColor) * float(sobelY[1+i][1+j]); 

        }
    }

    float edge = abs(sumX) + abs(sumY);


    
    edge = smoothstep(0.0, 0.25, edge);

    return vec3(edge);
}

vec4 char(vec2 p, int c){
    if (p.x<.0|| p.x>1. || p.y<0.|| p.y>1.) return vec4(0,0,0,1.0);
    return texture2D(u_font, p/16. + fract(vec2(c, 15-c/16)/16.));
}

const float pixel_size = 0.01;
const float letter_change_speed = 0.01;

void main(){
    vec2 uv = vec2(v_uv.x * -1.0 + 1.0, v_uv.y); // Mirrored UVs to make posing for a snapshot easier.
    // For non-mirrored:
    // uv = v_uv;

    float aspect_ratio = u_resolution.x/u_resolution.y;

    vec2 noise_uv = uv - mod(uv, vec2(pixel_size/aspect_ratio, pixel_size));
    vec3 pixel = edgeDetection(noise_uv);
    noise_uv.y = mod(noise_uv.y + letter_change_speed * u_time, 1.0);
    float noise = texture2D(u_noise, noise_uv).r;
    float temp = noise*25.0 + 65.0;
    if(fract(temp) < 5.0){
        noise = floor(temp);
    }else{
        noise = ceil(temp);
    }

    vec2 pixel_uv = (
        vec2((1.0/pixel_size)*aspect_ratio, (1.0/pixel_size)) *
        mod(uv, vec2(pixel_size/aspect_ratio, pixel_size))
    );

    vec3 char = char(pixel_uv, int(noise)).rgb;
    float intensity = length(pixel) / sqrt(3.0);

    vec3 col = vec3(1.5 * intensity * char.r, intensity * char.r, 0.0);

    gl_FragColor = vec4(col, 1.0);
}