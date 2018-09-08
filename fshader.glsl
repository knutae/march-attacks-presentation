precision mediump float;
varying vec2 vTexCoord;
uniform float uAspect;
uniform float uTime;

float origin_sphere(vec3 p, float radius) {
    return length(p) - radius;
}

float scene(vec3 p) {
    return origin_sphere(p, 0.5);
}

vec3 ray_march(vec3 start_pos, vec3 direction) {
    vec3 p = start_pos;
    float hit_color = 1.0;
    for (int i = 0; i < 20; i++) {
        float dist = scene(p);
        if (dist < 0.01) {
            return vec3(hit_color);
        }
        p += direction * dist;
        hit_color -= 0.05;
    }
    return vec3(0.0);
}

void main() {
    float u = vTexCoord.x - 1.0;
    float v = (vTexCoord.y - 1.0) / uAspect;
    vec3 start_pos = vec3(u, v, -5.0);
    vec3 direction = vec3(0.0, 0.0, 1.0);
    vec3 color = ray_march(start_pos, direction);
    gl_FragColor = vec4(color, 1.0);
}
