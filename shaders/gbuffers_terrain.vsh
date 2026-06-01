#version 330 compatibility

uniform float frameTimeCounter;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;

void main() {
    vec4 position = gl_Vertex;
    
    float sway = sin(position.x + frameTimeCounter * 2.5) * cos(position.z + frameTimeCounter * 1.8) * 0.06;
    position.x += sway;
    position.z += sway;
    
    gl_Position = gl_ModelViewProjectionMatrix * position;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
}