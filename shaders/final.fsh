#version 330 compatibility

uniform sampler2D colortex0;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform float rainStrength;
uniform vec3 fogColor;

in vec2 texcoord;

layout(location = 0) out vec4 color;

float hash(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    vec2 uv = texcoord - 0.5;
    float r2 = dot(uv, uv);
    
    float distortion = 1.0 + r2 * 0.04;
    vec2 distortedUV = uv * distortion + 0.5;

    float dropScale = 12.0;
    vec2 dropUV = distortedUV * dropScale + vec2(0.0, frameTimeCounter * 2.5);
    vec2 cell = floor(dropUV);
    vec2 local = fract(dropUV) - 0.5;
    float dropMask = smoothstep(0.4, 0.05, length(local));
    float dropSpawn = step(0.8, hash(cell));
    distortedUV += (local * 0.12) * dropMask * dropSpawn * rainStrength;

    float sanityIntensity = smoothstep(50.0, 5.0, cameraPosition.y);
    float sanityWarpX = sin(uv.y * 12.0 + frameTimeCounter * 1.5) * 0.002;
    float sanityWarpY = cos(uv.x * 14.0 + frameTimeCounter * 1.2) * 0.002;
    distortedUV += vec2(sanityWarpX, sanityWarpY) * sanityIntensity;

    if (distortedUV.x < 0.0 || distortedUV.x > 1.0 || distortedUV.y < 0.0 || distortedUV.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float baseCA = r2 * 0.002;
    float impactSpike = step(0.98, hash(vec2(floor(frameTimeCounter * 8.0), 1.0))) * 0.02;
    float ca = baseCA + impactSpike;

    float r = texture(colortex0, distortedUV + vec2(ca, 0.0)).r;
    float g = texture(colortex0, distortedUV).g;
    float b = texture(colortex0, distortedUV - vec2(ca, 0.0)).b;
    vec3 c = vec3(r, g, b);

    float moveEvent = step(0.96, hash(vec2(floor(frameTimeCounter * 2.0), 12.0)));
    float moveTime = fract(frameTimeCounter * 2.0);
    float moveIntensity = moveEvent * smoothstep(0.0, 0.15, moveTime) * smoothstep(0.5, 0.15, moveTime);
    float periphery = smoothstep(0.25, 0.9, length(uv * distortion));
    float actualBlur = moveIntensity * periphery;

    if (actualBlur > 0.01) {
        float randAngle = hash(vec2(floor(frameTimeCounter * 2.0), 13.0)) * 6.28318;
        vec2 dir = vec2(cos(randAngle), sin(randAngle));
        vec3 blurSum = vec3(0.0);
        for(int i = -3; i <= 3; i++) {
            vec2 offsetUV = distortedUV + dir * (float(i) * 0.012 * actualBlur);
            blurSum += texture(colortex0, clamp(offsetUV, 0.0, 1.0)).rgb;
        }
        c = mix(c, blurSum / 7.0, actualBlur * 0.9);
    }

    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    
    float lumaFog = dot(fogColor, vec3(0.299, 0.587, 0.114));
    float nightFactor = 1.0 - smoothstep(0.02, 0.15, lumaFog);
    float currentSaturation = mix(0.7, 0.2, nightFactor);
    
    c = mix(vec3(luma), c, currentSaturation);

    float breathTimer = fract(frameTimeCounter * 0.35);
    vec2 breathUV = uv - vec2(0.0, -0.4);
    breathUV.y -= breathTimer * 0.2;
    float breathRadius = mix(0.1, 0.6, breathTimer);
    float breathDist = length(breathUV) / breathRadius;
    float breathMask = smoothstep(1.0, 0.0, breathDist);
    float vapor = sin(breathUV.x * 30.0 + frameTimeCounter * 2.0) * cos(breathUV.y * 30.0 - frameTimeCounter * 3.0);
    vapor = vapor * 0.5 + 0.5;
    float breathFade = smoothstep(0.0, 0.2, breathTimer) * smoothstep(1.0, 0.6, breathTimer);
    float breathAlpha = breathMask * vapor * breathFade * 0.15;
    float isFreezing = max(step(85.0, cameraPosition.y), step(lumaFog, 0.05));
    c = mix(c, vec3(0.7, 0.8, 0.9), breathAlpha * isFreezing);

    float darkness = 1.0 - smoothstep(0.0, 0.4, luma);
    float distFromCenter = length(uv * distortion);
    
    float beat = sin(frameTimeCounter * 5.0) * cos(frameTimeCounter * 12.0);
    float pulseIntensity = mix(0.95, 0.8 + (beat * 0.05), darkness);
    
    float vignette = smoothstep(pulseIntensity, 0.3, distFromCenter);
    c *= vignette;

    float underground = smoothstep(62.0, 20.0, cameraPosition.y);
    float noiseIntensity = 0.03 + (0.08 * underground);
    
    float noiseVal = hash(distortedUV * (frameTimeCounter * 15.0 + 1.0));
    c += (noiseVal - 0.5) * noiseIntensity * darkness;

    vec2 recPos = uv - vec2(-0.4, 0.4);
    float recDot = smoothstep(0.012, 0.008, length(recPos / distortion));
    float blink = step(0.5, fract(frameTimeCounter * 0.8));
    c = mix(c, vec3(0.8, 0.1, 0.1), recDot * blink);

    c = pow(c, vec3(0.8));

    c = clamp(c, 0.0, 1.0);

    color = vec4(c, 1.0);
}


