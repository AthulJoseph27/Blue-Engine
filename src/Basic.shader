 #shader vertex
 #version 330 core
  in vec3 vp;
  void main() {
    gl_Position = vec4(vp, 1.0);
  }
  
#shader fragment
#version 330 core
  out vec4 frag_colour;
  uniform vec4 u_Color;
  void main() {
    frag_colour = u_Color;
  }