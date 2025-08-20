#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

// Uniforms
uniform float progress;
uniform vec2 folderCenter;
uniform vec2 resolution;
uniform sampler2D folderTexture;
uniform sampler2D entriesTexture;

// Output
out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / resolution.xy;
    vec2 center = folderCenter / resolution.xy;
    
    // Calculate distance from folder center
    float distance = length(uv - center);
    
    // Create morphing effect based on progress and distance
    float morphFactor = smoothstep(0.0, 1.0, progress - distance * 0.5);
    
    // Sample both textures
    vec4 folderColor = texture(folderTexture, uv);
    vec4 entriesColor = texture(entriesTexture, uv);
    
    // Mix colors based on morph factor
    vec4 color = mix(folderColor, entriesColor, morphFactor);
    
    // Add particle-like effects during transition
    if (progress > 0.2 && progress < 0.8) {
        float noise = fract(sin(dot(uv * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
        if (noise > 0.95) {
            color += vec4(1.0, 1.0, 1.0, 0.3) * (1.0 - abs(progress - 0.5) * 2.0);
        }
    }
    
    fragColor = color;
}