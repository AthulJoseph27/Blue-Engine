#include <iostream>
#include <string.h>
#include <fstream>
#include <sstream>

#include "Renderer.h"
#include "VertexBuffer.h"
#include "IndexBuffer.h"
#include "VertexArray.h"
#include "Shader.h"

static void GLClearError()
{
    while (glGetError() != GL_NO_ERROR)
        ;
}

static void GLCheckError()
{
    while (GLenum error = glGetError())
    {
        std::cout << "[OpenGL ERROR] (" << error << ")" << std::endl;
    }
}

int main()
{

    GLFWwindow *window;

    /* Initialize the library */
    if (!glfwInit())
        return -1;

    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);

    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(640, 480, "Window", NULL, NULL);
    if (!window)
    {
        glfwTerminate();
        return -1;
    }

    /* Make the window's context current */
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    if (glewInit() != GLEW_OK)
    {
        std::cout << "Error while initializing glew" << std::endl;
    }

    std::cout << glGetString(GL_VERSION) << std::endl;

    float points[12] = {
        -0.5f, -0.5f, 0.0f, // 0
        -0.5f, 0.5f, 0.0f,  // 1
        0.5f, 0.5f, 0.0f,   // 2
        0.5f, -0.5f, 0.0f   // 3
    };

    unsigned int indices[6] = {
        0, 1, 2,
        2, 3, 0};

    unsigned int vao = 0;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    VertexArray va;
    VertexBuffer vb(points, 12 * sizeof(float));
    VertexBufferLayout layout;
    layout.Push<float>(3);
    va.AddBuffer(vb, layout);

    // glEnableVertexAttribArray(0);
    // glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    IndexBuffer ib(indices, 6);

    Shader shader("Basic.shader");
    shader.Bind();

    shader.SetUniform4f("u_Color", 0.0f, 0.7f, 0.5f, 1.0f);

    va.Unbind();
    vb.Unbind();
    ib.Unbind();
    shader.Unbind();

    Renderer renderer;
    float r = 0.0f, increment = 0.05f;

    while (!glfwWindowShouldClose(window))
    {
        // wipe the drawing surface clear
        renderer.Clear();

        shader.Bind();
        shader.SetUniform4f("u_Color", r, 0.7f, 0.5f, 1.0f);

        renderer.Draw(va, ib, shader);
        if (r > 1.0f)
            increment = -0.05;
        else if (r < 0.0f)
            increment = 0.05f;

        r += increment;

        // update other events like input handling
        glfwPollEvents();
        // put the stuff we've been drawing onto the display
        glfwSwapBuffers(window);
    }

    return 0;
}

//clang++ -framework CoreFoundation -framework OpenGL -std=c++14 main.cpp $(pkg-config --cflags --libs glew glfw3)