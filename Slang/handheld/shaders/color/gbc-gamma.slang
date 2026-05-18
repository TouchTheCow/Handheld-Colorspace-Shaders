#version 450

// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to use GBC's LCD gamma curves, as it doesn't use the standard gamma. The GBC screen has a brighter image overall, with the dark shadows being darker for a more contrast look from the display.
// A gamma can be adjusted as GBC's gamma can vary depending on the light source angle. Top light angle is brighter while the bottom light angle is darker. Still is overall brighter than raw RGB gamma ramp.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float gamma_mode;
	float adjust_gamma;
} params;

#pragma parameter gamma_mode "Gamma Ramp: 0=Raw, 1=GBC" 1.0 0.0 1.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma (Darker-Brighter)" 0.0 -0.5 1.0 0.05

#define gamma_mode params.gamma_mode

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

const uint OGGamma[32] = {
      0u,   8u,  16u,  24u,  33u,  41u,  49u,  57u,
     66u,  74u,  82u,  90u,  99u, 107u, 115u, 123u,
    132u, 140u, 148u, 156u, 165u, 173u, 181u, 189u,
    198u, 206u, 214u, 222u, 231u, 239u, 247u, 255u
    };

const uint GBCGamma[32] = {
      0u,   8u,  15u,  26u,  37u,  49u,  67u,  85u,
     97u, 110u, 121u, 134u, 140u, 148u, 154u, 160u,
    170u, 180u, 188u, 196u, 202u, 207u, 212u, 217u,
    222u, 228u, 232u, 237u, 246u, 252u, 254u, 255u
    };

uvec3 GammaAdjustment(uint r, uint g, uint b)
{
    uint RampR = uint(r >> 3);
    uint RampG = uint(g >> 3);
    uint RampB = uint(b >> 3);

    uint R, G, B;

    if (gamma_mode == 0.0)
	{
        R = OGGamma[RampR];
        G = OGGamma[RampG];
        B = OGGamma[RampB];
    }
    else if (gamma_mode == 1.0)
	{
        R = GBCGamma[RampR];
        G = GBCGamma[RampG];
        B = GBCGamma[RampB];
    }
    return uvec3(R, G, B);
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#define conv(f) ((f >= 1.0) ? 255 : (f <= 0.0 ? 0 : int(floor(f * 256.0))))

void main()
{
	vec4 img = texture(Source, vTexCoord);

	// convert standard vec4 to uint color values
	uvec4 int_img = uvec4(conv(img.r), conv(img.g), conv(img.b), conv(img.a));

	uint r = (int_img.r) & 0xff;
	uint g = (int_img.g) & 0xff;
	uint b = (int_img.b) & 0xff;

	uvec3 output_i = GammaAdjustment(r, g, b);
	vec3  output_f = vec3(output_i) * vec3(1./255.);
	FragColor = vec4(pow(output_f, vec3(2.2 / (params.adjust_gamma + 2.2))), img.a);
}
