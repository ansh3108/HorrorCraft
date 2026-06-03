#version 330 compatibility

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float frameTimeCounter;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 viewVector;
in vec3 normal;
in vec3 worldPos;

layout(location = 0) out vec4 color;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void main() {
    vec4 tex = texture(gtexture, texcoord);
    if (tex.a < 0.1) discard;

    vec2 wavePos = worldPos.xz * 1.5 + frameTimeCounter * 0.8;
    float ripple = noise(wavePos) * 0.5 + noise(wavePos * 2.0) * 0.25;

    float glitchEvent = step(0.985, hash(vec2(floor(frameTimeCounter * 3.0), 17.0)));
    float glitchWarp = noise(worldPos.xz * 8.0) * glitchEvent * 2.5;

    vec3 perturbedNormal = normalize(normal + vec3(ripple * 0.15 + glitchWarp, 0.0, ripple * 0.15 - glitchWarp));

    float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    vec3 baseInk = vec3(luma * 0.02, luma * 0.03, luma * 0.04);

    float fresnel = pow(1.0 - max(dot(viewVector, perturbedNormal), 0.0), 3.0);
    float specular = pow(max(dot(reflect(-viewVector, perturbedNormal), viewVector), 0.0), 24.0);

    vec3 ambientLight = texture(lightmap, lmcoord).rgb;

    vec3 finalColor = baseInk * ambientLight;
    
    vec3 refColor = vec3(0.15, 0.18, 0.22);
    vec3 ghostlyRef = vec3(0.6, 0.7, 0.75);
    refColor = mix(refColor, ghostlyRef, glitchEvent * fresnel);

    finalColor += refColor * fresnel * ambientLight * 0.8;
    finalColor += vec3(0.2, 0.25, 0.3) * specular * ambientLight * 0.4;

    float alpha = mix(0.75, 0.98, fresnel);

    color = vec4(finalColor, alpha);
}


