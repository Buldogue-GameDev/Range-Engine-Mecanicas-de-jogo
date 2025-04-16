uniform sampler2D bgl_RenderedTexture; 

const float vignette_size = 0.4;
const float tolerance = 0.2;

void main(void)
{           
    vec4 col_value = texture2D(bgl_RenderedTexture, gl_TexCoord[0].st);
    
    float col_avg = (col_value[0] + col_value[1] + col_value[2]) * 0.333;
                            
    float ratio = 2.0 * col_avg;
    float b = max(0.0, (1.0 - ratio));
    float r = max(0.0, (ratio - 1.0));
    float g = 1.0 - r - b;
 
    vec4 color_vision = vec4(r, g, b, 1.0);
 
    vec2 deltaTexCoord = gl_TexCoord[0].st - vec2(0.5);
    vec2 powers = vec2(pow(deltaTexCoord.x, 2.0), pow(deltaTexCoord.y, 2.0));  
        
    float radiusSqrd = pow(vignette_size, 2.0);    
    float gradient = smoothstep(radiusSqrd - tolerance, radiusSqrd + tolerance, powers.x + powers.y * 0.3);

    gl_FragColor = mix(color_vision, vec4(1.0, 0.0, 0.0, 1.0), gradient);
    gl_FragColor.a = 1.0;
}
