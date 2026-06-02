#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 fogColor;
uniform int moonPhase;
uniform float frameTimeCounter;

in vec2 texcoord;

layout(location = 0) out vec4 color;

float hash(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec3 baseColor = texture(colortex0, texcoord).rgb;
    float depth = texture(depthtex0, texcoord).r;

    float lumaFog = dot(fogColor, vec3(0.299, 0.587, 0.114));
    vec3 spookyFog = mix(fogColor, vec3(lumaFog), 0.45);

    float isNight = smoothstep(0.4, 0.1, lumaFog);
    float isBloodMoon = (moonPhase == 0) ? 1.0 : 0.0;
    
    vec3 bloodColor = vec3(0.5, 0.02, 0.02);
    spookyFog = mix(spookyFog, bloodColor, isBloodMoon * isNight * 0.85);

    if (depth == 1.0) {
        color = vec4(spookyFog, 1.0);
        return;
    }

    vec3 ndc = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * vec4(ndc, 1.0);
    viewPos.xyz /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * vec4(viewPos.xyz, 1.0);

    float dist = length(viewPos.xyz);
    
    float darknessMultiplier = mix(0.15, 0.02, lumaFog); 
    float fogFactor = exp(-darknessMultiplier * dist);
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    float mistHeight = smoothstep(0.5, -3.0, worldPos.y);
    float mistDensity = noise(worldPos.xz * 0.4 - frameTimeCounter * 0.6);
    float mist = mistHeight * mistDensity * (1.0 - fogFactor);
    
    vec3 ambientTint = mix(vec3(1.0), vec3(1.2, 0.3, 0.3), isBloodMoon * isNight * 0.5);
    baseColor *= ambientTint;

    vec3 finalColor = mix(spookyFog, baseColor, fogFactor);
    finalColor = mix(finalColor, spookyFog * 1.2, mist * 0.85);

    color = vec4(finalColor, 1.0);
}

