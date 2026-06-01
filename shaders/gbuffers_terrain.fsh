#version 330 compatibility

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float frameTimeCounter;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;

layout(location = 0) out vec4 color;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main() {
    color = texture(gtexture, texcoord) * glcolor;
    
    float timeBlock = floor(frameTimeCounter * 14.0);
    float noiseVal = hash(timeBlock);
    
    float blackout = step(0.04, hash(timeBlock * 1.5));
    float stutter = 0.8 + (noiseVal * 0.2);
    
    vec2 lm = lmcoord;
    lm.x *= stutter * blackout;
    
    float underglow = smoothstep(-0.2, -0.9, normal.y);
    float topShadow = smoothstep(0.2, 0.9, normal.y);
    
    float artificialLight = lm.x;
    lm.x += artificialLight * underglow * 2.0;
    lm.x -= artificialLight * topShadow * 0.85;
    lm.x = clamp(lm.x, 0.0, 1.0);
    
    color *= texture(lightmap, lm);
    
    if (color.a < 0.1) discard;
}