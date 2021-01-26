#pragma once
#include <string>
#include "GL/glew.h"
#include "GLFW/glfw3.h"
#include <unordered_map>

struct ShaderProgramSource
{
    std::string VertexSource;
    std::string FragmentSource;
};

class Shader
{
private:
    unsigned int m_RendererID;
    std::string m_FilePath;
    std::unordered_map<std::string, int> m_UniformLocationCache;

public:
    Shader(const std::string &filepath);
    ~Shader();

    void Bind() const;
    void Unbind() const;

    void SetUniform1i(const std::string &name, int value);
    void SetUniform1f(const std::string &name, float value);
    void SetUniform4f(const std::string &name, float v0, float v1, float v2, float v3);

private:
    unsigned int CompileShader(unsigned int type, const std::string &source);
    int GetUniformLocation(const std::string &name);
    unsigned int CreateShader(const std::string vertexShader, const std::string fragmentShader);
    struct ShaderProgramSource ParseShader(std::string filePath);
};