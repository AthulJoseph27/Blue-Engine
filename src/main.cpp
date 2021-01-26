#include <iostream>
#include <string.h>
#include <fstream>
#include <sstream>

#include "Renderer.h"
#include "VertexBuffer.h"
#include "IndexBuffer.h"
#include "VertexArray.h"

struct ShaderProgramSource
{
    std::string VertexSource;
    std::string FragmentSource;
};
static struct ShaderProgramSource ParseShader(std::string filePath)
{
    enum class ShaderType
    {
        NONE = -1,
        VERTEX = 0,
        FRAGMENT = 1
    };
    std::ifstream stream(filePath);
    std::string line;
    std::stringstream ss[2];
    ShaderType type = ShaderType::NONE;

    while (getline(stream, line))
    {
        if (line.find("#shader") != std::string::npos)
        {
            if (line.find("vertex") != std::string::npos)
                type = ShaderType::VERTEX;
            else if (line.find("fragment") != std::string::npos)
                type = ShaderType::FRAGMENT;
        }
        else
            ss[(int)type] << line << "\n";
    }
    return {ss[0].str(), ss[1].str()};
}

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

static unsigned int CompileShader(unsigned int type, const std::string &source)
{
    unsigned int id = glCreateShader(type);
    const char *src = source.c_str();
    glShaderSource(id, 1, &src, NULL);
    glCompileShader(id);

    int result;
    glGetShaderiv(id, GL_COMPILE_STATUS, &result);
    if (result == GL_FALSE)
    {
        int length;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
        char message[length];
        glGetShaderInfoLog(id, length, &length, message);
        std::cout << "Failed to compile " << (type == GL_VERTEX_SHADER ? "vertex" : "fragment") << "shader" << std::endl;
        std::cout << message << std::endl;
        glDeleteShader(id);
        return 0;
    }

    return id;
}

static unsigned int CreateShader(const std::string vertexShader, const std::string fragmentShader)
{
    unsigned int program = glCreateProgram();

    unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
    unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

    glAttachShader(program, fs);
    glAttachShader(program, vs);
    glLinkProgram(program);

    return program;
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

    struct ShaderProgramSource shaderSource = ParseShader("Basic.shader");
    unsigned int shader = CreateShader(shaderSource.VertexSource, shaderSource.FragmentSource);

    int location = glGetUniformLocation(shader, "u_Color");
    if (location == -1)
        std::cout << "Location not found" << std::endl;
    glUniform4f(location, 0.0f, 0.7f, 0.5f, 1.0f);
    vb.Unbind();
    glUseProgram(0);
    glBindVertexArray(0);
    float r = 0.0f, increment = 0.05f;

    while (!glfwWindowShouldClose(window))
    {
        // wipe the drawing surface clear
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glUseProgram(shader);
        glUniform4f(location, r, 0.7f, 0.5f, 1.0f);
        // glBindVertexArray(vao);
        va.Bind();
        ib.Bind();
        if (r > 1.0f)
            increment = -0.05;
        else if (r < 0.0f)
            increment = 0.05f;

        r += increment;

        // draw points 0-3 from the currently bound VAO with current in-use shader
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);
        // update other events like input handling
        glfwPollEvents();
        // put the stuff we've been drawing onto the display
        glfwSwapBuffers(window);
    }

    return 0;
}

//clang++ -framework CoreFoundation -framework OpenGL -std=c++14 main.cpp $(pkg-config --cflags --libs glew glfw3)