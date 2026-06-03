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

    float timeBlock = floor(frameTimeCounter * 0.4);
    float spawnChance = hash(vec2(timeBlock, 1.0));
    float figX = hash(vec2(timeBlock, 2.0));
    
    vec2 figCenter = vec2(figX, 0.48);
    vec2 dUV = texcoord - figCenter;
    dUV.y *= 1.8;
    
    float head = length(dUV - vec2(0.0, 0.04));
    float body = length(max(abs(dUV - vec2(0.0, -0.02)) - vec2(0.002, 0.04), 0.0));
    float figureShape = min(head - 0.006, body - 0.004);
    
    float flicker = step(0.85, hash(vec2(floor(frameTimeCounter * 15.0), 3.0)));
    float isFigure = step(figureShape, 0.0) * step(0.9, spawnChance) * flicker * step(0.98, depth);
    
    baseColor = mix(baseColor, vec3(0.005, 0.005, 0.008), isFigure);

    float lumaFog = dot(fogColor, vec3(0.299, 0.587, 0.114));
    vec3 spookyFog = mix(fogColor, vec3(lumaFog), 0.7) * 0.15;

    float isNight = smoothstep(0.4, 0.1, lumaFog);
    float isBloodMoon = (moonPhase == 0) ? 1.0 : 0.0;
    
    vec3 bloodColor = vec3(0.2, 0.01, 0.01);
    spookyFog = mix(spookyFog, bloodColor, isBloodMoon * isNight * 0.8);

    vec3 ndc = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * vec4(ndc, 1.0);
    viewPos.xyz /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * vec4(viewPos.xyz, 1.0);
    vec3 rayDir = normalize(worldPos.xyz);

    if (depth == 1.0) {
        vec3 skyColor = spookyFog;
        if (rayDir.y > 0.0) {
            vec2 skyUV = rayDir.xz / (rayDir.y + 0.08);
            skyUV += frameTimeCounter * 0.015;
            
            float n = noise(skyUV * 2.0) * 0.5;
            n += noise(skyUV * 4.0 - frameTimeCounter * 0.03) * 0.25;
            n += noise(skyUV * 8.0 + frameTimeCounter * 0.05) * 0.125;
            
            float cloudDensity = smoothstep(0.3, 0.8, n);
            vec3 darkMass = vec3(0.005, 0.005, 0.008);
            
            skyColor = mix(skyColor, darkMass, cloudDensity * smoothstep(0.0, 0.2, rayDir.y));
            skyColor = mix(skyColor, vec3(0.005, 0.005, 0.008), isFigure);
        }
        color = vec4(skyColor, 1.0);
        return;
    }

    float dist = length(viewPos.xyz);
    
    float darknessMultiplier = mix(0.035, 0.015, lumaFog); 
    float fogFactor = exp(-darknessMultiplier * dist);
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    float mistHeight = smoothstep(1.0, -1.0, worldPos.y);
    float mistDensity = noise(worldPos.xz * 0.4 - frameTimeCounter * 0.6);
    float mist = mistHeight * mistDensity * (1.0 - fogFactor);
    
    vec3 ambientTint = mix(vec3(0.9), vec3(1.1, 0.4, 0.4), isBloodMoon * isNight * 0.4);
    baseColor *= ambientTint;

    vec3 finalColor = mix(spookyFog, baseColor, fogFactor);
    finalColor = mix(finalColor, spookyFog * 1.2, mist * 0.25);

    color = vec4(finalColor, 1.0);
}


