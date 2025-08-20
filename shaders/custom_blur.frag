#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

// Uniforms
uniform float time;
uniform vec2 resolution;
uniform float blurRadius;
uniform vec2 focusPoint;
uniform sampler2D inputTexture;

// Output
out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / resolution.xy;
    vec2 center = focusPoint / resolution.xy;
    
    // Calculate distance from focus point for radial blur
    float distance = length(uv - center);
    
    // Dynamic blur intensity based on distance and animation progress
    float blur = blurRadius * distance * 0.01;
    
    vec4 color = vec4(0.0);
    float total = 0.0;
    
    // Simple box blur implementation
    for (float x = -blur; x <= blur; x += blur / 3.0) {
        for (float y = -blur; y <= blur; y += blur / 3.0) {
            vec2 offset = vec2(x, y);
            color += texture(inputTexture, uv + offset);
            total += 1.0;
        }
    }
    
    color /= total;
    
    // Add subtle darkening for focus effect
    color.rgb *= 0.7 + 0.3 * (1.0 - distance);
    
    fragColor = color;
}