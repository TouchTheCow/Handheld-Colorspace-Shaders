#version 450

// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to correct the gamma curves for each RGB channels that the filter uses from Nintendo Switch Online GBC filter. It uses colder gamma ramps and helps out to replicate the look when loading the NSO-GBC shader afterwards.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

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

const uint gammaRampR[32] = {
      0u,   0u,   0u,   1u,   4u,   8u,  14u,  21u,
     28u,  38u,  47u,  57u,  66u,  78u,  90u, 103u,
    114u, 127u, 138u, 151u, 163u, 175u, 186u, 198u,
    207u, 215u, 225u, 233u, 240u, 247u, 252u, 255u
	};

const uint gammaRampG[32] = {
      1u,   3u,   8u,  12u,  19u,  28u,  35u,  47u,
     56u,  66u,  78u,  89u, 102u, 112u, 127u, 140u,
    151u, 166u, 177u, 188u, 200u, 210u, 219u, 228u,
    235u, 241u, 248u, 250u, 255u, 255u, 255u, 255u
	};

const uint gammaRampB[32] = {
      1u,   7u,  14u,  22u,  27u,  40u,  50u,  60u,
     71u,  84u,  92u, 106u, 118u, 130u, 141u, 154u,
    166u, 177u, 190u, 199u, 210u, 217u, 227u, 235u,
    240u, 248u, 250u, 254u, 255u, 255u, 255u, 255u
	};

#define conv(f) ((f >= 1.0) ? 255 : (f <= 0.0 ? 0 : int(floor(f * 256.0))))

void main()
{
	vec4 img = texture(Source, vTexCoord);

	// convert standard vec4 to uint color values
	uvec4 int_img = uvec4(conv(img.r), conv(img.g), conv(img.b), conv(img.a));

	uint r = (int_img.r) & 0xff;
	uint g = (int_img.g) & 0xff;
	uint b = (int_img.b) & 0xff;

	// apply the ramp
	uint R = gammaRampR[r >> 3];
	uint G = gammaRampG[g >> 3];
	uint B = gammaRampB[b >> 3];

	uvec3 output_i = uvec3(R, G, B);
	vec3  output_f = vec3(output_i) * vec3(1./255.);

	FragColor = vec4(output_f, 1.0);
}
