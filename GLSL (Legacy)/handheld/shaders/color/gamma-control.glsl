// GBA-Gamma shader pass by Pokefan531
// Based on stock shader to add gamma control
// This is used for GBA shaders with just simple gamma adjustment. Also mGBA fix is adjusting the RGB balance to bring green to 255 from 251 in the libretro core to bring a proper white and grey balance.

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter mgba_fix "mGBA Fix" 0.0 0.0 1.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma" 2.2 1.0 4.0 0.05

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float mgba_fix;
uniform COMPAT_PRECISION float adjust_gamma;
#else
#define mgba_fix 0.0
#define adjust_gamma 2.2
#endif

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_TEXTURE texture2D
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;

void main()
{
  gl_Position = MVPMatrix * VertexCoord;
  TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)

void main()
{
  vec4 color = texture(Source, vTexCoord);
  color.rgb *= vec3(1.0, (1.0 + (0.016 * mgba_fix)), 1.0);
  color.rgb = pow(color.rgb, vec3(adjust_gamma / 2.2));
  FragColor = color;
}
#endif
