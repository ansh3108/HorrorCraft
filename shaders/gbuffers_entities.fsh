#version 330 compatibility

uniform sampler2D gtexture;
uniform sampler2D lightmap;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    vec4 tex = texture(gtexture, texcoord);
    if (tex.a < 0.1) discard;

    color = tex * glcolor;
    color *= texture(lightmap, lmcoord);
}