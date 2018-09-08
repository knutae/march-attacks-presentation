attribute vec2 aVertexPosition;
varying vec2 vTexCoord;
uniform vec2 uOffset;
void main() {
    vTexCoord = aVertexPosition + uOffset;
    gl_Position = vec4(aVertexPosition, 0, 1);
}
