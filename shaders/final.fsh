#version 330 compatibility

uniform sampler2D colortex0;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform float rainStrength;

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
    
    float distortion = 1.0 + r2 * 0.15;
    vec2 distortedUV = uv * distortion + 0.5;

    float dropScale = 12.0;
    vec2 dropUV = distortedUV * dropScale + vec2(0.0, frameTimeCounter * 2.5);
    vec2 cell = floor(dropUV);
    vec2 local = fract(dropUV) - 0.5;
    float dropMask = smoothstep(0.4, 0.05, length(local));
    float dropSpawn = step(0.8, hash(cell));
    distortedUV += (local * 0.12) * dropMask * dropSpawn * rainStrength;

    float sanityIntensity = smoothstep(50.0, 5.0, cameraPosition.y);
    float sanityWarpX = sin(uv.y * 12.0 + frameTimeCounter * 1.5) * 0.006;
    float sanityWarpY = cos(uv.x * 14.0 + frameTimeCounter * 1.2) * 0.006;
    distortedUV += vec2(sanityWarpX, sanityWarpY) * sanityIntensity;

    if (distortedUV.x < 0.0 || distortedUV.x > 1.0 || distortedUV.y < 0.0 || distortedUV.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float baseCA = r2 * 0.015;
    float impactSpike = step(0.98, hash(vec2(floor(frameTimeCounter * 8.0), 1.0))) * 0.04;
    float ca = baseCA + impactSpike;

    float r = texture(colortex0, distortedUV + vec2(ca, 0.0)).r;
    float g = texture(colortex0, distortedUV).g;
    float b = texture(colortex0, distortedUV - vec2(ca, 0.0)).b;
    vec3 c = vec3(r, g, b);

    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(luma), c, 0.55);

    float darkness = 1.0 - smoothstep(0.0, 0.4, luma);
    float distFromCenter = length(uv * distortion);
    
    float beat = sin(frameTimeCounter * 5.0) * cos(frameTimeCounter * 12.0);
    float pulseIntensity = mix(0.95, 0.75 + (beat * 0.15), darkness);
    
    float vignette = smoothstep(pulseIntensity, 0.25, distFromCenter);
    c *= vignette;

    float underground = smoothstep(62.0, 20.0, cameraPosition.y);
    float noiseIntensity = 0.15 + (0.45 * underground);
    
    float noise = hash(distortedUV * (frameTimeCounter * 15.0 + 1.0));
    c += (noise - 0.5) * noiseIntensity * darkness;

    vec2 recPos = uv - vec2(-0.4, 0.4);
    float recDot = smoothstep(0.012, 0.008, length(recPos / distortion));
    float blink = step(0.5, fract(frameTimeCounter * 0.8));
    c = mix(c, vec3(0.8, 0.1, 0.1), recDot * blink);

    c = clamp(c, 0.0, 1.0);

    color = vec4(c, 1.0);
}

