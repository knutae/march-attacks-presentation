precision mediump float;
varying vec2 vTexCoord;
uniform float uAspect;
uniform float uTime;

void main() {
    vec3 color = vec3(
        sin(vTexCoord.x + uTime) / 2.0 + 0.5,
        sin(vTexCoord.y + uTime + 1.0) / 2.0 + 0.5,
        sin(-uTime) / 2.0 + 0.5);
    gl_FragColor = vec4(color, 1.0);
}
