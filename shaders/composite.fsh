#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;

uniform vec3 fogColor;
uniform int moonPhase;

in vec2 texcoord;

layout(location = 0) out vec4 color;

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

    float dist = length(viewPos.xyz);
    
    float darknessMultiplier = mix(0.15, 0.02, lumaFog); 
    float fogFactor = exp(-darknessMultiplier * dist);
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    vec3 ambientTint = mix(vec3(1.0), vec3(1.2, 0.3, 0.3), isBloodMoon * isNight * 0.5);
    baseColor *= ambientTint;

    color = vec4(mix(spookyFog, baseColor, fogFactor), 1.0);
}

