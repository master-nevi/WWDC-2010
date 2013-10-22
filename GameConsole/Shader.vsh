attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

uniform float translate;

void main()
{
    gl_Position = position;
    gl_Position.y += sin(translate) * 0.5;
    gl_Position.x += cos(translate) * 0.5;

    colorVarying = color;
}
