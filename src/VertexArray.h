#pragma once
#include "VertexBuffer.h"
#include "VertexBufferLayout.h"

class VertexArray
{

private:
    unsigned int m_RenedererID;

public:
    VertexArray();
    ~VertexArray();

    void AddBuffer(const VertexBuffer &vb, const VertexBufferLayout &layout);
    void Bind() const;
    void UnBind() const;
};

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
        glVertexAttribPointer(i, element.count, element.type, element.normalize, layout.GetStride(), 0);
        offSet += element.count * VertexBufferElement::GetSizeOfType(element.type);
    }
}