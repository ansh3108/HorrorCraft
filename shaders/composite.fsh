#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;

uniform vec3 fogColor;

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
    vec3 baseColor = texture(colortex0, texcoord).rgb;
    float depth = texture(depthtex0, texcoord).r;

    float lumaFog = dot(fogColor, vec3(0.299, 0.587, 0.114));
    vec3 spookyFog = mix(fogColor, vec3(lumaFog), 0.45);

    if (depth == 1.0) {
        color = vec4(spookyFog, 1.0);
        return;
    }

    vec3 ndc = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * vec4(ndc, 1.0);
    viewPos.xyz /= viewPos.w;

    float dist = length(viewPos.xyz);
    float fogFactor = exp(-0.025 * dist);
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    color = vec4(mix(spookyFog, baseColor, fogFactor), 1.0);
}
