uniform sampler2D bgl_RenderedTexture;
uniform sampler2D bgl_DepthTexture;
uniform vec2 bgl_TextureCoordinateOffset[9];
uniform float bgl_RenderedTextureWidth;
uniform float bgl_RenderedTextureHeight;
uniform sampler2D bgl_DataTextures[1];

vec2 res = vec2(bgl_RenderedTextureWidth, bgl_RenderedTextureHeight);

// Parameters
uniform float zNear = 0.01; 
float zFar = 300.0;
float outlineThickness = 1.5; 
vec3 outlineColor = vec3(0.0);
float wiggleFrequency = 0.08; 
float wiggleAmplitude = 2.0;

#define offs bgl_TextureCoordinateOffset
#define SCREEN_TEXTURE bgl_RenderedTexture
#define NORMAL_TEXTURE bgl_DataTextures[0]
#define DEPTH_TEXTURE bgl_DepthTexture
#define FRAGCOORD gl_FragCoord.xy
#define VIEWPORT_SIZE res
#define SCREEN_UV gl_TexCoord[0].xy;
mat4 INV_PROJECTION_MATRIX = inverse(gl_ProjectionMatrix);

// Sobel Filter x
const mat3 Sy = mat3(
	vec3(1.0, 0.0, -1.0),
	vec3(2.0, 0.0, -2.0),
	vec3(1.0, 0.0, -1.0)
);

// Sobel Filter y
const mat3 Sx = mat3(
	vec3(1.0, 2.0, 1.0),
	vec3(0.0, 0.0, 0.0),
	vec3(-1.0, -2.0, -1.0)
);

// Retrieve and scale depth from the depth buffer
float depth(sampler2D depth_texture, vec2 screen_uv,  mat4 inv_projection_matrix){
	float raw_depth = texture(depth_texture, screen_uv)[0];
    //return raw_depth;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, raw_depth);
    vec4 view_space = inv_projection_matrix * vec4(ndc, 1.0);	
	view_space.xyz /= view_space.w;
	float linear_depth = view_space.z ; 
	float scaled_depth = (zFar-zNear)/(zNear  + linear_depth*(zNear -zFar));
	return scaled_depth;
}

// Compute edges detection from depth using x,y sobel filters
float sobel_depth(in vec2 uv,  in vec2 offset,  mat4 inv_projection_matrix) {
	float d00 = depth(DEPTH_TEXTURE, uv + offset * vec2(-1,-1),inv_projection_matrix);
	float d01 = depth(DEPTH_TEXTURE, uv + offset * vec2(-1, 0),inv_projection_matrix);
	float d02 = depth(DEPTH_TEXTURE, uv + offset * vec2(-1, 1),inv_projection_matrix);
	
	float d10 = depth(DEPTH_TEXTURE, uv + offset * vec2( 0,-1),inv_projection_matrix);
	float d11 = depth(DEPTH_TEXTURE, uv + offset * vec2( 0, 0),inv_projection_matrix);
	float d12 = depth(DEPTH_TEXTURE, uv + offset * vec2( 0, 1),inv_projection_matrix);
	
	float d20 = depth(DEPTH_TEXTURE, uv + offset * vec2( 1,-1),inv_projection_matrix);
	float d21 = depth(DEPTH_TEXTURE, uv + offset * vec2( 1, 0),inv_projection_matrix);
	float d22 = depth(DEPTH_TEXTURE, uv + offset * vec2( 1, 1),inv_projection_matrix);
	
	float xSobelDepth =
	Sx[0][0] * d00 + Sx[1][0] * d10 + Sx[2][0] * d20 +
	Sx[0][1] * d01 + Sx[1][1] * d11 + Sx[2][1] * d21 +
	Sx[0][2] * d02 + Sx[1][2] * d12 + Sx[2][2] * d22;
	
	float ySobelDepth =
	Sy[0][0] * d00 + Sy[1][0] * d10 + Sy[2][0] * d20 +
	Sy[0][1] * d01 + Sy[1][1] * d11 + Sy[2][1] * d21 +
	Sy[0][2] * d02 + Sy[1][2] * d12 + Sy[2][2] * d22;
	return  sqrt(pow(xSobelDepth, 2.0) + pow(ySobelDepth, 2.0));
}

float luminance(vec3 color) {
	const vec3 magic = vec3(0.2125, 0.7154, 0.0721);
	return dot(magic, color);
}

// Compute edges detection from normals using x,y sobel filters
float sobel_normal(in vec2 uv,  in vec2 offset) {
	float normal00 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2(-1,-1)).rgb);
	float normal01 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2(-1, 0)).rgb);
	float normal02 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2(-1, 1)).rgb);
	
	float normal10 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 0,-1)).rgb);
	float normal11 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 0, 0)).rgb);
	float normal12 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 0, 1)).rgb);
	
	float normal20 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 1,-1)).rgb);
	float normal21 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 1, 0)).rgb);
	float normal22 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 1, 1)).rgb);
	
	float xSobelNormal =
	Sx[0][0] * normal00 + Sx[1][0] * normal10 + Sx[2][0] * normal20 +
	Sx[0][1] * normal01 + Sx[1][1] * normal11 + Sx[2][1] * normal21 +
	Sx[0][2] * normal02 + Sx[1][2] * normal12 + Sx[2][2] * normal22;
	
	float ySobelNormal =
	Sy[0][0] * normal00 + Sy[1][0] * normal10 + Sy[2][0] * normal20 +
	Sy[0][1] * normal01 + Sy[1][1] * normal11 + Sy[2][1] * normal21 +
	Sy[0][2] * normal02 + Sy[1][2] * normal12 + Sy[2][2] * normal22;
	return  sqrt(pow(xSobelNormal, 2.0) + pow(ySobelNormal, 2.0));
}

// Just dont ask
float hash(vec2 p){
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void main() {  
	vec2 offset = outlineThickness/ VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	// Displacement to add a little bit of hand-drawn wiggly effect
	vec2 displ =  vec2((hash(FRAGCOORD.xy) * sin(FRAGCOORD.y * wiggleFrequency)) ,
	(hash(FRAGCOORD.xy) * cos(FRAGCOORD.x * wiggleFrequency))) * wiggleAmplitude /VIEWPORT_SIZE;
	// Access the depth buffer
	float depth = depth(DEPTH_TEXTURE, uv, INV_PROJECTION_MATRIX);
    vec3 screencolor = texture(SCREEN_TEXTURE, uv).rgb; 
    vec3 pixelColor = screencolor;
	
	float pixelLuma = luminance(pixelColor);
	float modVal = 11.0;
	
	// Apply hatching based on luminance value (from darker to lighter zones
	// Dark Zones
	if(pixelLuma <= 0.35) {
		if (mod((uv.y + displ.y) * VIEWPORT_SIZE.y , modVal)  < outlineThickness) {
			pixelColor = outlineColor;
		}
	}
	// Grey Dark
	if (pixelLuma <= 0.45 ) {
		 if (mod((uv.x + displ.x) * VIEWPORT_SIZE.x , modVal)  < outlineThickness) {
			pixelColor = mix(pixelColor, outlineColor, 0.25);
		}
	}
	// Light Dark
	if (pixelLuma <= 0.80) {
     if (mod((uv.x + displ.x) * VIEWPORT_SIZE.y + (uv.y + displ.y) * VIEWPORT_SIZE.x, modVal) <= outlineThickness) {
			pixelColor = mix(pixelColor, outlineColor, 0.5);
		}
	}

	// Avoid depth cross-hatching (sky and background)
	// NOTE: for some reason, the interval [0,1] seems inverted
	if(depth<0.01){
        pixelColor = screencolor;
	}

	// Edge detection using depth buffer
	float edgeDepth = sobel_depth(uv+displ, offset, INV_PROJECTION_MATRIX);
	// Edge detection normal buffer
	float edgeNormal = sobel_normal(uv+displ, offset);
	// Mix both edge detection
	float outline = smoothstep(0.0,1.0, 25.0*edgeDepth + edgeNormal);
	// Mix color and edges

	gl_FragColor.rgb = mix(pixelColor, outlineColor, outline);
}
