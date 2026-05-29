#version 330 compatibility 

uniform sampler2D colortex0;
uniform float frameTimeCounter;

in vec2 texcoord;

layout(location = 0) out vec4 color;

float noiseGen(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {
    vec2 uv = texcoord - 0.5;
    float d = dot(uv, uv);

    vec2 distortedUV = texcoord + uv * d * 0.08;

    if (distortedUV.x < 0.0 || distortedUV.x > 1.0 || distortedUV.y < 0.0 || distortedUV.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float chromaDist = d * 0.007;
    float r = texture(colortex0, distortedUV + vec2(chromaDist, 0.0)).r;
    float g = texture(colortex0, distortedUV).g;
    float b = texture(colortex0, distortedUV - vec2(chromaDist, 0.0)).b;
    vec3 c = vec3(r,g,b);

    float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));

    float grain = noiseGen(distortedUV * (frameTimeCounter + 0.1));
    float grainMask = smoothstep(0.7, 0.0, luma);
    c += (grain - 0.5) * 0.15 * grainMask;

    float vignette = smoothstep(0.85, 0.3, length(uv));
    c *= vignette;

    float lineFreq = sin(distortedUV.y * 800.0 + frameTimeCounter * 2.0); 
    c -= lineFreq * 0.015;

    c = mix(c, floor(c * 16.0) / 16.0, 0.4);

    color = vec4(c, 1.0);

}
