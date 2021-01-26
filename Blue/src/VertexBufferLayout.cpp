#include "VertexBufferLayout.h"

template <>
void VertexBufferLayout::Push<float>(unsigned int count)
{
    m_Elements.push_back({count, GL_FLOAT, GL_FALSE});
    m_Stride += sizeof(GLfloat) * count;
}

template <>
void VertexBufferLayout::Push<unsigned int>(unsigned int count)
{
    m_Elements.push_back({count, GL_UNSIGNED_INT, GL_FALSE});
    m_Stride += sizeof(GLuint) * count;
}

template <>
void VertexBufferLayout::Push<unsigned char>(unsigned int count)
{
    m_Elements.push_back({count, GL_UNSIGNED_BYTE, GL_TRUE});
    m_Stride += sizeof(GLbyte) * count;
}
