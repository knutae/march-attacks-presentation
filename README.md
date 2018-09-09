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

## Add plane

## Different materials

## Shadows

## Soft shadows

## Fog

## Reflections

## More shapes

Show: Box, round box. Mention torus, cylinder, etc.

## Constructive Solid Geometry

Union, intersect, difference.

## Repeated geometry

## Combine repetition and CSG
