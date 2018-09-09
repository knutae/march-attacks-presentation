precision mediump float;
varying vec2 vTexCoord;
uniform float uAspect;
uniform float uTime;

struct material {
    float ambient;
    float diffuse;
    float specular;
    float shininess;
    vec3 color;
};

const material blue_sphere_material = material(0.1, 0.9, 0.8, 6.0, vec3(0.5, 0.5, 1.0));
const material green_sphere_material = material(0.1, 0.9, 0.8, 6.0, vec3(0.5, 1.0, 0.5));
const material red_sphere_material = material(0.1, 0.9, 0.8, 10.0, vec3(1.0, 0.5, 0.5));

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

void closest_material(inout float dist, inout material mat, float new_dist, material new_mat) {
    if (new_dist < dist) {
        dist = new_dist;
        mat = new_mat;
    }
}

material scene_material(vec3 p) {
    float dist = origin_sphere(p, 0.3);
    material mat = blue_sphere_material;
    closest_material(dist, mat, sphere_at(p, vec3(-0.6, 0.0, 0.0), 0.25), green_sphere_material);
    closest_material(dist, mat, sphere_at(p, vec3(0.6, 0.0, 0.0), 0.25), red_sphere_material);
    return mat;
}

bool ray_march(inout vec3 p, vec3 direction) {
    for (int i = 0; i < 20; i++) {
        float dist = scene(p);
        if (dist < 0.01) {
            return true;
        }
        if (dist > 10.0) {
            return false;
        }
        p += direction * dist;
    }
    return false;
}

vec3 estimate_normal(vec3 p) {
    float epsilon = 0.01;
    return normalize(vec3(
        scene(vec3(p.x + epsilon, p.y, p.z)) - scene(vec3(p.x - epsilon, p.y, p.z)),
        scene(vec3(p.x, p.y + epsilon, p.z)) - scene(vec3(p.x, p.y - epsilon, p.z)),
        scene(vec3(p.x, p.y, p.z + epsilon)) - scene(vec3(p.x, p.y, p.z - epsilon))
    ));
}

vec3 ray_reflection(vec3 direction, vec3 normal) {
    return 2.0 * dot(-direction, normal) * normal + direction;
}

vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    vec3 normal = estimate_normal(p);
    vec3 light_direction = normalize(vec3(-1.0));
    float diffuse = max(0.0, mat.diffuse * dot(normal, -light_direction));
    vec3 reflection = ray_reflection(ray_direction, normal);
    float specular = pow(max(0.0, mat.specular * dot(reflection, -light_direction)), mat.shininess);
    return mat.color * (diffuse + mat.ambient) + vec3(specular);
}

void main() {
    float u = vTexCoord.x - 1.0;
    float v = (vTexCoord.y - 1.0) / uAspect;
    float eye_distance = 2.0;
    float rotation_speed = 2.0;
    vec3 eye_position = vec3(
        sin(uTime * rotation_speed) * eye_distance,
        1.0 + sin(uTime) * 0.2,
        cos(uTime * rotation_speed) * eye_distance);
    vec3 forward = normalize(-eye_position);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = cross(up, forward);
    float focal_length = 1.0;
    vec3 start_pos = eye_position + forward * focal_length + right * u + up * v;
    vec3 direction = normalize(start_pos - eye_position);
    vec3 p = start_pos;
    vec3 color = vec3(0.0);
    if (ray_march(p, direction)) {
        color = phong_lighting(p, scene_material(p), direction);
    }
    gl_FragColor = vec4(color, 1.0);
}
