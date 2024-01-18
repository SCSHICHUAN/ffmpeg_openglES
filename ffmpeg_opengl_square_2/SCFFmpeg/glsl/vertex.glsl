
#version 300 core

layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 textPos;

out vec2 outTextPos;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


void main() {
   
    // 注意乘法要从右向左读
    gl_Position = projection * view * model * vec4(pos, 1.0);
    outTextPos = vec2(textPos.x, 1.0 - textPos.y);
    
}

