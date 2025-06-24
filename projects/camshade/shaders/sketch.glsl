uniform sampler2D u_texture;

uniform vec2 u_resolution;
uniform float u_time;

varying vec2 v_uv;

float brightnesss(vec2 uv){
    return dot(texture2D(u_texture, uv).rgb, vec3(0.2126, 0.7152, 0.0722));
}


void main() {
    vec2 uv = vec2(v_uv.x * -1.0 + 1.0, v_uv.y); // Mirrored UVs to make posing for a snapshot easier.
    // For non-mirrored:
    // uv = v_uv;
    vec3 col;

    vec3 line_col = vec3(0.3, 0.3, 0.38);
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
    float tolerance = 0.25;

    if(g > tolerance)
        col = line_col;
    else
        col = background;

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
    if(brightnesss < shading_threshold_3){
        if(mod(gl_FragCoord.x + gl_FragCoord.y, 5.0) == 0.0){
            col = line_col;
        }
    }
    if(brightnesss < shading_threshold_4){
        if(mod(gl_FragCoord.x - gl_FragCoord.y, 5.0) == 0.0){
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