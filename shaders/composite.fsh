#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;

uniform float far;
uniform vec3 fogColor;

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    vec3 skyBase = fogColor * vec3(0.3, 0.38, 0.32);

    if (depth == 1.0) {
        color.rgb = skyBase;
        return;
    }

    vec3 ndc = vec3(texcoord, depth) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * vec4(ndc, 1.0);
    viewPos.xyz /= viewPos.w;

    float dist = length(viewPos.xyz) / far;
    float fogFactor = exp(-5.5 * dist * dist);
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    color.rgb = mix(skyBase, color.rgb, fogFactor);
}