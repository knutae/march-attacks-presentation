# Raymarching with shaders

## Introduction

Explain raytracing basics. Explain raymarching with distance fields. Whiteboard.

## Skeleton project for WebGL

Prepared in advance. Explain a bit.

```glsl
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
```

## First example

Raymarched sphere with orthographic projection.

```glsl
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
```

## Multiple spheres, position offsets

```glsl
float sphere_at(vec3 p, vec3 centre, float radius) {
    return origin_sphere(p - centre, radius);
}

float scene(vec3 p) {
    float dist = origin_sphere(p, 0.3);
    dist = min(dist, sphere_at(p, vec3(-0.6, 0.0, 0.0), 0.25));
    dist = min(dist, sphere_at(p, vec3(0.6, 0.0, 0.0), 0.25));
    return dist;
}
```

## Perspective projection

```glsl
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
```

## Rotate camera

```glsl
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
    vec3 color = ray_march(start_pos, direction);
    gl_FragColor = vec4(color, 1.0);
}
```

The up vector is a bit off when the camera is not horizontal. This also makes the length of the right vector a bit off. Let's fix both issues.

```glsl
    vec3 forward = normalize(-eye_position);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, forward));
    up = cross(-right, forward);
```

## Normals and phong lightning

Quickly explain the [Phong lighting model](https://en.wikipedia.org/wiki/Phong_reflection_model).

We need a way to calculate surface normals.

```glsl
vec3 estimate_normal(vec3 p) {
    float epsilon = 0.01;
    return normalize(vec3(
        scene(vec3(p.x + epsilon, p.y, p.z)) - scene(vec3(p.x - epsilon, p.y, p.z)),
        scene(vec3(p.x, p.y + epsilon, p.z)) - scene(vec3(p.x, p.y - epsilon, p.z)),
        scene(vec3(p.x, p.y, p.z + epsilon)) - scene(vec3(p.x, p.y, p.z - epsilon))
    ));
}
```

Define a material.

```glsl
struct material {
    float ambient;
    float diffuse;
    float specular;
    vec3 color;
};

const material sphere_material = material(0.1, 0.9, 1.0, vec3(0.5, 0.5, 1.0));
```

Change the `ray_march` function to detect the position.

```glsl
bool ray_march(inout vec3 p, vec3 direction) {
    float total_dist = 0.0;
    for (int i = 0; i < 20; i++) {
        float dist = scene(p);
        if (dist < 0.01) {
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
```

Add a dummy `phong_lighting` function and use it from `main`.

```glsl
vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    return vec3(1.0); // FIXME
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
        color = phong_lighting(p, sphere_material, direction);
    }
    gl_FragColor = vec4(color, 1.0);
}
```

Diffuse lighting is calculated using the dot product of the normal and the direction towards the light.

```glsl
vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    vec3 normal = estimate_normal(p);
    vec3 light_direction = normalize(vec3(-1.0));
    float diffuse = max(0.0, mat.diffuse * dot(normal, -light_direction));
    return mat.color * (diffuse + mat.ambient);
}
```

Specular lighting is calculated by reflecting the ray and then taking the dot product with the direction towards the light.

```glsl
vec3 ray_reflection(vec3 direction, vec3 normal) {
    return 2.0 * dot(-direction, normal) * normal + direction;
}

vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    vec3 normal = estimate_normal(p);
    vec3 light_direction = normalize(vec3(-1.0));
    float diffuse = max(0.0, mat.diffuse * dot(normal, -light_direction));
    vec3 reflection = ray_reflection(ray_direction, normal);
    float specular = max(0.0, mat.specular * dot(reflection, -light_direction));
    return mat.color * (diffuse + mat.ambient) + vec3(specular);
}
```

Shininess controls the size of the specular highlights.

```glsl
struct material {
    float ambient;
    float diffuse;
    float specular;
    float shininess;
    vec3 color;
};

const material sphere_material = material(0.1, 0.9, 0.8, 6.0, vec3(0.5, 0.5, 1.0));
```

```glsl
vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    vec3 normal = estimate_normal(p);
    vec3 light_direction = normalize(vec3(-1.0));
    float diffuse = max(0.0, mat.diffuse * dot(normal, -light_direction));
    vec3 reflection = ray_reflection(ray_direction, normal);
    float specular = pow(max(0.0, mat.specular * dot(reflection, -light_direction)), mat.shininess);
    return mat.color * (diffuse + mat.ambient) + vec3(specular);
}
```

## Different materials

Calculate different materials by duplicating scene code. Not elegant, but works.

```glsl
const material blue_sphere_material = material(0.1, 0.9, 0.8, 6.0, vec3(0.5, 0.5, 1.0));
const material green_sphere_material = material(0.1, 0.9, 0.8, 6.0, vec3(0.5, 1.0, 0.5));
const material red_sphere_material = material(0.1, 0.9, 0.8, 10.0, vec3(1.0, 0.5, 0.5));

float blue_sphere(vec3 p) { return origin_sphere(p, 0.3); }
float green_sphere(vec3 p) { return sphere_at(p, vec3(-0.6, -0.05, 0.0), 0.25); }
float red_sphere(vec3 p) { return sphere_at(p, vec3(0.6, -0.05, 0.0), 0.25); }

float scene(vec3 p) {
    float dist = blue_sphere(p);
    dist = min(dist, green_sphere(p));
    dist = min(dist, red_sphere(p));
    return dist;
}

void closest_material(inout float dist, inout material mat, float new_dist, material new_mat) {
    if (new_dist < dist) {
        dist = new_dist;
        mat = new_mat;
    }
}

material scene_material(vec3 p) {
    float dist = blue_sphere(p);
    material mat = blue_sphere_material;
    closest_material(dist, mat, green_sphere(p), green_sphere_material);
    closest_material(dist, mat, red_sphere(p), red_sphere_material);
    return mat;
}
```

```glsl
    if (ray_march(p, direction)) {
        color = phong_lighting(p, scene_material(p), direction);
    }
```

## Add floor plane

```glsl
const material floor_material = material(0.1, 0.9, 0.8, 10.0, vec3(1.0));

float horizontal_plane(vec3 p, float height) {
    return p.y - height;
}

float scene(vec3 p) {
    float dist = blue_sphere(p);
    dist = min(dist, green_sphere(p));
    dist = min(dist, red_sphere(p));
    dist = min(dist, floor_plane(p));
    return dist;
}

material scene_material(vec3 p) {
    float dist = blue_sphere(p);
    material mat = blue_sphere_material;
    closest_material(dist, mat, green_sphere(p), green_sphere_material);
    closest_material(dist, mat, red_sphere(p), red_sphere_material);
    closest_material(dist, mat, floor_plane(p), floor_material);
    return mat;
}
```

## Shadows

Use ray marching to calculate shadows. Start with an offset to avoid being to close to the surface.

```glsl
float shadow_multiplier(vec3 p, vec3 light_direction) {
    p = p - light_direction * 0.05;
    if (ray_march(p2, -light_direction)) {
        return 0.0;
    } else {
        return 1.0;
    }
}

vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    vec3 normal = estimate_normal(p);
    vec3 light_direction = normalize(vec3(-1.0));
    float shadow = shadow_multiplier(p, light_direction);
    float diffuse = max(0.0, mat.diffuse * dot(normal, -light_direction)) * shadow;
    vec3 reflection = ray_reflection(ray_direction, normal);
    float specular = pow(max(0.0, mat.specular * dot(reflection, -light_direction)), mat.shininess) * shadow;
    return mat.color * (diffuse + mat.ambient) + vec3(specular);
}
```

## Soft shadows

The ray marching algorithm has some knowledge about how close the a ray was to hitting an object. Use a custom ray marching function to implement soft shadows.

```glsl
float soft_shadow(vec3 p, vec3 light_direction, float softness) {
    p += light_direction * 0.1;
    float total_dist = 0.1;
    float res = 1.0;
    for (int i = 0; i < 20; i++) {
        float dist = scene(p);
        if (dist < 0.01) {
            return 0.0;
        }
        total_dist += dist;
        res = min(res, dist / (softness * total_dist));
        if (total_dist > 10.0) {
            break;
        }
        p += light_direction * dist;
    }
    return res;
}

vec3 phong_lighting(vec3 p, material mat, vec3 ray_direction) {
    vec3 normal = estimate_normal(p);
    vec3 light_direction = normalize(vec3(-1.0));
    float shadow = soft_shadow(p, -light_direction, 0.1);
    float diffuse = max(0.0, mat.diffuse * dot(normal, -light_direction)) * shadow;
    vec3 reflection = ray_reflection(ray_direction, normal);
    float specular = pow(max(0.0, mat.specular * dot(reflection, -light_direction)), mat.shininess) * shadow;
    return mat.color * (diffuse + mat.ambient) + vec3(specular);
}
```

## Fog

Improve image quality by blending with a background color based on the distance from the focal plane.

```glsl
vec3 blend(vec3 base_color, vec3 blend_color, float blend_amount) {
    return base_color * (1.0 - blend_amount) + blend_color * blend_amount;
}

const vec3 background_color = vec3(0.8, 0.9, 1.0);

vec3 apply_fog(vec3 color, float total_distance) {
    return blend(color, background_color, min(1.0, total_distance / 10.0));
}
```

```glsl
    vec3 color = background_color;
    if (ray_march(p, direction)) {
        color = phong_lighting(p, scene_material(p), direction);
        color = apply_fog(color, length(p - start_pos));
    }
```

## Checkerboard floor

It's raytracing. We should have a checkerboard floor.

```glsl
const material floor_material_1 = material(0.1, 0.9, 0.8, 10.0, vec3(1.0));
const material floor_material_2 = material(0.1, 0.9, 0.8, 10.0, vec3(0.5));

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

material scene_material(vec3 p) {
    float dist = blue_sphere(p);
    material mat = blue_sphere_material;
    closest_material(dist, mat, green_sphere(p), green_sphere_material);
    closest_material(dist, mat, red_sphere(p), red_sphere_material);
    closest_material(dist, mat, floor_plane(p), floor_material(p));
    return mat;
}
```

## Reflections

Add a single iteration of reflections.

```glsl
struct material {
    float ambient;
    float diffuse;
    float specular;
    float shininess;
    float reflection;
    vec3 color;
};

const material blue_sphere_material = material(0.1, 0.9, 0.8, 6.0, 0.3, vec3(0.5, 0.5, 1.0));
```

```glsl
vec3 apply_reflections(vec3 color, material mat, vec3 p, vec3 direction) {
    if (mat.reflection <= 0.0) {
        return color;
    }
    vec3 reflection_color = background_color;
    direction = ray_reflection(direction, estimate_normal(p));
    p += 0.05 * direction;
    if (ray_march(p, direction)) {
        reflection_color = phong_lighting(p, scene_material(p), direction);
    }
    return blend(color, reflection_color, mat.reflection);
}
```

```glsl
    if (ray_march(p, direction)) {
        material mat = scene_material(p);
        color = phong_lighting(p, mat, direction);
        color = apply_reflections(color, mat, p, direction);
        color = apply_fog(color, length(p - start_pos));
    }
```

Multiple levels of reflections must be implemented without recursion in the shader. Use a for loop and multiply the reflection for each material to reduce the effect for each step.

```glsl
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
            color = blend(color, reflection_color, reflection);
            mat = scene_material(p);
            reflection *= mat.reflection;
        } else {
            color = blend(color, reflection_color, reflection);
            break;
        }
    }
    return color;
}
```

## Boxes

Distance functions for boxes can be implemented using the absolute value of the position.

```glsl
float origin_box(vec3 p, vec3 dimensions) {
    vec3 a = abs(p);
    return length(max(abs(p) - dimensions, 0.0));
}

float box_at(vec3 p, vec3 centre, vec3 dimensions) {
    return origin_box(p - centre, dimensions);
}

float blue_sphere(vec3 p) { return origin_sphere(p, 0.3); }
float green_sphere(vec3 p) { return sphere_at(p, vec3(-0.6, -0.05, 0.0), 0.25); }
float green_box(vec3 p) { return box_at(p, vec3(-0.6, -0.05, 0.0), vec3(0.25)); }
float red_sphere(vec3 p) { return sphere_at(p, vec3(0.6, -0.05, 0.0), 0.25); }
float floor_plane(vec3 p) { return horizontal_plane(p, -0.3); }

float scene(vec3 p) {
    float dist = blue_sphere(p);
    dist = min(dist, green_box(p));
    dist = min(dist, red_sphere(p));
    dist = min(dist, floor_plane(p));
    return dist;
}

material scene_material(vec3 p) {
    float dist = blue_sphere(p);
    material mat = blue_sphere_material;
    closest_material(dist, mat, green_box(p), green_sphere_material);
    closest_material(dist, mat, red_sphere(p), red_sphere_material);
    closest_material(dist, mat, floor_plane(p), floor_material(p));
    return mat;
}
```

This distance function does not give negative values for positions inside the box. This can be fixed, but is not needed for our example.

## Other distance functions

Mention torus, cylinder, etc.

## Constructive Solid Geometry

Union, intersect, difference.

## Repeated geometry

## Combine repetition and CSG
