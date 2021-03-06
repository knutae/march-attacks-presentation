precision mediump float;
varying vec2 vTexCoord;
uniform float uAspect;
uniform float uTime;

struct material {
    float ambient;
    float diffuse;
    float specular;
    float shininess;
    float reflection;
    vec3 color;
};

const material blue_material = material(0.1, 0.9, 0.8, 6.0, 0.3, vec3(0.5, 0.5, 1.0));
const material green_material = material(0.1, 0.9, 0.8, 6.0, 0.3, vec3(0.5, 1.0, 0.5));
const material red_material = material(0.1, 0.9, 0.8, 10.0, 0.3, vec3(1.0, 0.5, 0.5));
const material floor_material_1 = material(0.1, 0.9, 0.8, 10.0, 0.1, vec3(1.0));
const material floor_material_2 = material(0.1, 0.9, 0.8, 10.0, 0.1, vec3(0.5));

float origin_sphere(vec3 p, float radius) {
    return length(p) - radius;
}

float sphere_at(vec3 p, vec3 centre, float radius) {
    return origin_sphere(p - centre, radius);
}

float horizontal_plane(vec3 p, float height) {
    return p.y - height;
}

float origin_box(vec3 p, vec3 dimensions, float corner_radius) {
    vec3 a = abs(p);
    return length(max(abs(p) - dimensions, 0.0)) - corner_radius;
}

float box_at(vec3 p, vec3 centre, vec3 dimensions, float corner_radius) {
    return origin_box(p - centre, dimensions, corner_radius);
}

float origin_cylinder_z(vec3 p, float radius) {
    return length(p.xy) - radius;
}

float csg_union(float dist1, float dist2) {
    return min(dist1, dist2);
}

float csg_intersection(float dist1, float dist2) {
    return max(dist1, dist2);
}

float csg_subtraction(float dist1, float dist2) {
    return max(dist1, -dist2);
}

float blue_sphere(vec3 p) { return origin_sphere(p, 0.3); }
float blue_cylinder(vec3 p) { return origin_cylinder_z(p, 0.2); }
float blue_csg(vec3 p) { return csg_subtraction(blue_sphere(p), blue_cylinder(p)); }
float green_sphere(vec3 p) { return sphere_at(p, vec3(-0.6, -0.05, 0.0), 0.25); }
float green_box(vec3 p) { return box_at(p, vec3(-0.6, -0.05, 0.0), vec3(0.15), 0.1); }
float red_sphere(vec3 p) { return sphere_at(p, vec3(0.6, -0.05, 0.0), 0.25); }
float floor_plane(vec3 p) { return horizontal_plane(p, -0.3); }

float old_scene(vec3 p) {
    float dist = blue_csg(p);
    dist = min(dist, green_box(p));
    dist = min(dist, red_sphere(p));
    dist = min(dist, floor_plane(p));
    return dist;
}

void closest_material(inout float dist, inout material mat, float new_dist, material new_mat) {
    if (new_dist < dist) {
        dist = new_dist;
        mat = new_mat;
    }
}

material floor_material(vec3 p) {
    float grid_size = 0.8;
    float xmod = floor(mod(p.x / grid_size, 2.0));
    float zmod = floor(mod(p.z / grid_size, 2.0));
    if (mod(xmod + zmod, 2.0) < 1.0) {
        return floor_material_1;
    } else {
        return floor_material_2;
    }
}

material old_scene_material(vec3 p) {
    float dist = blue_csg(p);
    material mat = blue_material;
    closest_material(dist, mat, green_box(p), green_material);
    closest_material(dist, mat, red_sphere(p), red_material);
    closest_material(dist, mat, floor_plane(p), floor_material(p));
    return mat;
}

float repeated_boxes_x(vec3 p, vec3 dimensions, float corner_radius, float modulo) {
    vec3 q = vec3(mod(p.x, modulo) - 0.5 * modulo, p.yz);
    return origin_box(q, dimensions, corner_radius);
}

float repeated_boxes_xz(vec3 p, vec3 dimensions, float corner_radius, float modx, float modz) {
    vec3 q = vec3(mod(p.x, modx) - 0.5 * modx, p.y, mod(p.z, modz) - 0.5 * modz);
    return origin_box(q, dimensions, corner_radius);
}

float repeated_boxes_xyz(vec3 p, vec3 dimensions, float corner_radius, vec3 modulo) {
    vec3 q = mod(p - 0.5 * modulo, modulo) - 0.5 * modulo;
    return origin_box(q, dimensions, corner_radius);
}

float boxes(vec3 p) {
    return repeated_boxes_xyz(p, vec3(0.25), 0.05, vec3(3.0, 0.8, 3.0));
}

float fancy_object(vec3 p) {
    float sphere_size = 1.0 + 0.5 * sin(3.21 * uTime);
    float hollow_sphere = csg_subtraction(
        origin_sphere(p, sphere_size),
        origin_sphere(p, sphere_size * 0.95));
    float grid_size = 0.2 + 0.1 * cos(uTime);
    return csg_subtraction(
        hollow_sphere,
        repeated_boxes_xyz(p, vec3(grid_size * 0.4), grid_size * 0.05, vec3(grid_size)));
}

float twisted_object(vec3 p) {
    float amount = sin(uTime * 0.5) * 2.0;
    float c = cos(amount * p.y);
    float s = sin(amount * p.y);
    mat2 m = mat2(c, -s, s, c);
    vec3 q = vec3(m * p.xz, p.y);
    return fancy_object(q);
}

float new_plane(vec3 p) {
    return horizontal_plane(p, -1.0);
}

float scene(vec3 p) {
    float dist = twisted_object(p);
    dist = min(dist, new_plane(p));
    return dist;
}

material scene_material(vec3 p) {
    float dist = origin_sphere(p, 1.0); // optimization
    material mat = blue_material;
    closest_material(dist, mat, new_plane(p), floor_material(p));
    return mat;
}

bool ray_march(inout vec3 p, vec3 direction) {
    float total_dist = 0.0;
    for (int i = 0; i < 200; i++) {
        float dist = scene(p);
        if (dist < 0.001) {
            return true;
        }
        total_dist += dist;
        if (total_dist > 10.0) {
            return false;
        }
        p += direction * dist;
    }
    return false;
}

vec3 estimate_normal(vec3 p) {
    float epsilon = 0.001;
    return normalize(vec3(
        scene(vec3(p.x + epsilon, p.y, p.z)) - scene(vec3(p.x - epsilon, p.y, p.z)),
        scene(vec3(p.x, p.y + epsilon, p.z)) - scene(vec3(p.x, p.y - epsilon, p.z)),
        scene(vec3(p.x, p.y, p.z + epsilon)) - scene(vec3(p.x, p.y, p.z - epsilon))
    ));
}

vec3 ray_reflection(vec3 direction, vec3 normal) {
    return 2.0 * dot(-direction, normal) * normal + direction;
}

float soft_shadow(vec3 p, vec3 light_direction, float sharpness) {
    p += light_direction * 0.1;
    float total_dist = 0.1;
    float res = 1.0;
    for (int i = 0; i < 20; i++) {
        float dist = scene(p);
        if (dist < 0.01) {
            return 0.0;
        }
        total_dist += dist;
        res = min(res, sharpness * dist / total_dist);
        if (total_dist > 10.0) {
            break;
        }
        p += light_direction * dist;
    }
    return res;
}

const vec3 background_color = vec3(0.8, 0.9, 1.0);

vec3 apply_fog(vec3 color, float total_distance) {
    return mix(color, background_color, min(1.0, total_distance / 10.0));
}

vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    vec3 normal = estimate_normal(p);
    vec3 light_direction = normalize(vec3(-0.3, -1.0, -0.5));
    float shadow = soft_shadow(p, -light_direction, 20.0);
    float diffuse = max(0.0, mat.diffuse * dot(normal, -light_direction)) * shadow;
    vec3 reflection = ray_reflection(ray_direction, normal);
    float specular = pow(max(0.0, mat.specular * dot(reflection, -light_direction)), mat.shininess) * shadow;
    return mat.color * (diffuse + mat.ambient) + vec3(specular);
}

vec3 apply_reflections(vec3 color, material mat, vec3 p, vec3 direction) {
    float reflection = mat.reflection;
    for (int i = 0; i < 5; i++) {
        if (reflection <= 0.01) {
            break;
        }
        vec3 reflection_color = background_color;
        direction = ray_reflection(direction, estimate_normal(p));
        p += 0.05 * direction;
        if (ray_march(p, direction)) {
            reflection_color = phong_lighting(p, scene_material(p), direction);
            color = mix(color, reflection_color, reflection);
            mat = scene_material(p);
            reflection *= mat.reflection;
        } else {
            color = mix(color, reflection_color, reflection);
            break;
        }
    }
    return color;
}

void main() {
    float u = vTexCoord.x - 1.0;
    float v = (vTexCoord.y - 1.0) / uAspect;
    float eye_distance = 3.0;
    float rotation_speed = 1.0;
    vec3 eye_position = vec3(
        sin(uTime * rotation_speed) * eye_distance,
        1.0 + sin(uTime) * 0.2,
        cos(uTime * rotation_speed) * eye_distance);
    vec3 forward = normalize(-eye_position);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, forward));
    up = cross(-right, forward);
    float focal_length = 1.0;
    vec3 start_pos = eye_position + forward * focal_length + right * u + up * v;
    vec3 direction = normalize(start_pos - eye_position);
    vec3 p = start_pos;
    vec3 color = background_color;
    if (ray_march(p, direction)) {
        material mat = scene_material(p);
        color = phong_lighting(p, mat, direction);
        color = apply_reflections(color, mat, p, direction);
        color = apply_fog(color, length(p - start_pos));
    }
    gl_FragColor = vec4(color, 1.0);
}
