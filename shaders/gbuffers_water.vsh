#version 330 compatibility

uniform float frameTimeCounter;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 viewVector;
out vec3 normal;
out vec3 worldPos;

void main() {
    vec4 position = gl_Vertex;
    
    float wave = sin(position.x * 2.0 + frameTimeCounter * 1.5) * cos(position.z * 2.0 + frameTimeCounter * 1.2) * 0.04;
    position.y += wave;

    gl_Position = gl_ModelViewProjectionMatrix * position;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    

    vec4 viewPos = gl_ModelViewMatrix * position;
    viewVector = normalize(-viewPos.xyz);
    normal = normalize(gl_NormalMatrix * gl_Normal);
    worldPos = position.xyz;
}
