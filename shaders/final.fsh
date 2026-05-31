#version 330 compatibility

uniform sampler2D colortex0;
uniform float frameTimeCounter;

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

    if (distortedUV.x < 0.0 || distortedUV.x > 1.0 || distortedUV.y < 0.0 || distortedUV.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 c = texture(colortex0, distortedUV).rgb;

    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(luma), c, 0.55);

    float darkness = 1.0 - smoothstep(0.0, 0.4, luma);

    float distFromCenter = length(uv * distortion);
    float vignette = smoothstep(0.95, 0.35, distFromCenter);
    c *= vignette;

    float noise = hash(distortedUV * (frameTimeCounter * 15.0 + 1.0));
    c += (noise - 0.5) * 0.15 * darkness;

    vec2 recPos = uv - vec2(-0.4, 0.4);
    float recDot = smoothstep(0.012, 0.008, length(recPos / distortion));
    float blink = step(0.5, fract(frameTimeCounter * 0.8));
    c = mix(c, vec3(0.8, 0.1, 0.1), recDot * blink);

    c = clamp(c, 0.0, 1.0);

    color = vec4(c, 1.0);
}