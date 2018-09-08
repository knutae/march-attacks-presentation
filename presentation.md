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

## Rotate camera

## Normals and phong lightning

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
