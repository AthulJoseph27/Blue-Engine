#pragma once
#include "GL/glew.h"
#include "GLFW/glfw3.h"

class IndexBuffer
{
private:
    unsigned int m_RendererID;
    unsigned int m_Count;

public:
    IndexBuffer(const unsigned *data, unsigned int count);
    ~IndexBuffer();

    void Bind();
    void Unbind();

    inline unsigned int GetCount() const { return m_Count; }
};