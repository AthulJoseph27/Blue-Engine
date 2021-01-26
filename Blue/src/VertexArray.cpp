#include "VertexArray.h"

VertexArray::VertexArray()
{
    glGenVertexArrays(1, &m_RenedererID);
    glBindVertexArray(m_RenedererID);
}

VertexArray::~VertexArray()
{
    glDeleteVertexArrays(1, &m_RenedererID);
}

void VertexArray::Bind() const
{
    glBindVertexArray(m_RenedererID);
}

void VertexArray::UnBind() const
{
    glBindVertexArray(0);
}

void VertexArray::AddBuffer(const VertexBuffer &vb, const VertexBufferLayout &layout)
{
    Bind();
    vb.Bind();
    const auto &elements = layout.GetElements();
    unsigned int offSet = 0;
    for (unsigned int i = 0; i < elements.size(); i++)
    {
        const auto &element = elements[i];
        glEnableVertexAttribArray(i);
        glVertexAttribPointer(i, element.count, element.type, element.normalize, layout.GetStride(), (const void *)offSet);
        offSet += element.count * VertexBufferElement::GetSizeOfType(element.type);
    }
}