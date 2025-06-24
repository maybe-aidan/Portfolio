uniform sampler2D u_texture;

uniform vec2 u_resolution;
uniform float u_time;

varying vec2 v_uv;

float brightnesss(vec2 uv){
    return dot(texture2D(u_texture, uv).rgb, vec3(0.2126, 0.7152, 0.0722));
}

vec3 palette[8];

vec3 mapToGrayscale(vec3 color) {
    float grayscale = dot(color, vec3(0.299, 0.587, 0.114));
    float intensity = 1.0; // Adjust to brighten or darken (e.g., 0.5 for darker)
    return vec3(grayscale * intensity);
}

vec3 mapToPalette(vec3 color) {
    float minDist = 99999999.0;
    vec3 closestColor = palette[0];
    for(int i = 0; i < 8; i++){
        float dist = distance(color, palette[i]);
        if(minDist > dist) {
            minDist = dist;
            closestColor = palette[i];
        }
    }

    return closestColor;
}

vec3 quantizeColor(vec3 color, float bits) {
    float factor = pow(2.0, bits) - 1.0;
    return mapToPalette((floor(color * factor) / factor) + vec3(0.1));
}


void main() {
    vec2 uv = vec2(v_uv.x * -1.0 + 1.0, v_uv.y); // Mirrored UVs to make posing for a snapshot easier.
    // For non-mirrored:
    // uv = v_uv;
    vec3 col;

    // Try experimenting with different palettes!

    /* Moody Browns */
    
    palette[3] = vec3(0.1333, 0.0118, 0.0118); // Line
    palette[1] = vec3(1.0, 1.0, 0.87); // paper
    palette[2] = vec3(0.7216, 0.4706, 0.2824); // Crimson
    palette[0] = vec3(0.0, 0.0, 0.0); // Yellow
    palette[4] = vec3(0.3804, 0.2118, 0.0157); // Dark
    palette[5] = vec3(0.8745, 0.6235, 0.4471); // Skin 1
    palette[6] = vec3(0.95, 0.76, 0.58); // Skin 2
    palette[7] = vec3(0.4275, 0.2941, 0.1686); // Skin 3
    

    /* Blues */
    /*
    palette[0] = vec3(0.0235, 0.0235, 0.1216); // Line
    palette[1] = vec3(0.1137, 0.0235, 0.3608); 
    palette[2] = vec3(0.3176, 0.4745, 0.5216); 
    palette[3] = vec3(0.2275, 0.098, 0.3725); 
    palette[4] = vec3(0.2353, 0.1255, 0.4863); 
    palette[5] = vec3(0.2745, 0.1373, 0.4); 
    palette[6] = vec3(0.0431, 0.1137, 0.4196); 
    palette[7] = vec3(0.702, 0.0, 0.0); 
    */

    vec3 line_col = palette[0];//vec3(0.3, 0.3, 0.38);
    vec3 background = vec3(1.0, 1.0, 0.87);

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

    float g = abs(sumX) + abs(sumY);

    // Should be between 0 and 1.0
    // Controls how much detail is preserved.
    // Closer to 0 -> More detail
    // Closer to 1 -> Only the sharpest edges.
    float tolerance = 0.2;

    if(g > tolerance)
        col = line_col;
    else
        col = mapToPalette(texture2D(u_texture, uv).rgb);

    float shading_threshold_1 = 0.5;
    float shading_threshold_2 = 0.3;
    float shading_threshold_3 = 0.2;
    float shading_threshold_4 = 0.1;
    float shading_threshold_5 = 0.08;
    float shading_threshold_6 = 0.04;

    // Jitter effect
    vec2 jitter = vec2(
        sin(u_time + gl_FragCoord.y * 0.1) * 2.0,
        cos(u_time + gl_FragCoord.x * 0.1) * 2.0
    );

    float brightnesss = brightnesss(uv);
    /*
    if(brightnesss < shading_threshold_1){
        if(mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) == 0.0){
            col = line_col;
        }
    }
    if(brightnesss < shading_threshold_2){
        if(mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) == 0.0){
            col = line_col;
        }
    }
    */
    if(brightnesss < shading_threshold_3){
        if(mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) == 0.0){
            col = line_col;
        }
    }
    if(brightnesss < shading_threshold_4){
        if(mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) == 0.0){
            col = line_col;
        }
    } 
    if(brightnesss < shading_threshold_5){
        if(mod(gl_FragCoord.x + gl_FragCoord.y, 2.5) == 0.0){
            col = line_col;
        }
    }
    if(brightnesss < shading_threshold_6){
        if(mod(gl_FragCoord.x - gl_FragCoord.y, 2.5) == 0.0){
            col = line_col;
        }
    }


    gl_FragColor = vec4(col,1.0);
}