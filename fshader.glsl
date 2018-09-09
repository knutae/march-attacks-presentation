precision mediump float;
varying vec2 vTexCoord;
uniform float uAspect;
uniform float uTime;

float origin_sphere(vec3 p, float radius) {
    return length(p) - radius;
}

float sphere_at(vec3 p, vec3 centre, float radius) {
    return origin_sphere(p - centre, radius);
}

float scene(vec3 p) {
    float dist = origin_sphere(p, 0.3);
    dist = min(dist, sphere_at(p, vec3(-0.6, 0.0, 0.0), 0.25));
    dist = min(dist, sphere_at(p, vec3(0.6, 0.0, 0.0), 0.25));
    return dist;
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
    vec3 eye_position = vec3(0.0, 0.0, -1.0);
    vec3 forward = normalize(-eye_position);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = cross(up, forward);
    float focal_length = 0.5;
    vec3 start_pos = eye_position + forward * focal_length + right * u + up * v;
    vec3 direction = normalize(start_pos - eye_position);
    vec3 color = ray_march(start_pos, direction);
    gl_FragColor = vec4(color, 1.0);
}
