#version 450

// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to use GBA's LCD gamma curves, as both the GBA and the SP-001 uses its own curve that isn't a typical pure power gamma curve even if almost close with less contrast. This is also presented without black compensation, so full visible curves shown.
// A gamma can be adjusted as GBA's gamma can vary depending on the light source angle. Top light angle is darker while the bottom light angle is lighter. On Adjust Gamma, GBA can go from -0.85 to 1.25 from light to dark by light angle, while the SP-001 can range from -0.6 to 0.6 on the Adjust Gamma settings.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float gamma_mode;
	float adjust_gamma;
} params;

#pragma parameter gamma_mode "Gamma Ramp: 0=Raw,1=GBA,2=SP001" 1.0 0.0 2.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma (Darker-Brighter)" 0.0 -1.0 1.25 0.05

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

const uint GBAGamma[32] = {
      0u,   3u,   6u,  10u,  15u,  25u,  36u,  50u,
     62u,  71u,  82u,  92u, 102u, 109u, 116u, 124u,
    131u, 138u, 145u, 152u, 160u, 168u, 176u, 184u,
    193u, 202u, 211u, 218u, 229u, 240u, 249u, 255u
    };

const uint GBASPGamma[32] = {
      0u,   2u,   5u,   8u,  13u,  20u,  28u,  39u,
     49u,  57u,  66u,  75u,  84u,  90u,  97u, 105u,
    111u, 119u, 125u, 133u, 141u, 149u, 158u, 167u,
    176u, 187u, 197u, 207u, 220u, 235u, 247u, 255u
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
        R = GBAGamma[RampR];
        G = GBAGamma[RampG];
        B = GBAGamma[RampB];
    }
    else if (gamma_mode == 2.0)
	{
        R = GBASPGamma[RampR];
        G = GBASPGamma[RampG];
        B = GBASPGamma[RampB];
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
