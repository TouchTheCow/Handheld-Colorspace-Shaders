#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from the Gameboy Advance early revisions (up to late 2001) that uses Sharp's manufactured displays. GBA's Sharp displays are the ones that are found on many 40-pin connectors.

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
	float mode;
} global;

#pragma parameter mode "Color Profile (1=sRGB,2=DCI,3=Adobe,4=Rec2020)" 1.0 1.0 4.0 1.0
int color_mode = int(global.mode);

#define target_gamma 2.2
#define display_gamma 2.2

/*
We'll define our color weights in this pattern:
	r,   rg,  rb,  0.0,  //red channel
	gr,  g,   gb,  0.0,  //green channel
	br,  bg,  b,   0.0,  //blue channel
	blr, blg, blb, lum   //alpha channel; we'll hide lum at the end, too
*/

const mat4 GBA_sRGB = mat4(
	0.8988, 0.1163, 0.1831, 0.0,  //red channel
	0.2229, 0.6217, 0.2438, 0.0,  //green channel
	-0.1217, 0.2620, 0.5731, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.8915   //alpha channel
); 

const mat4 GBA_DCI = mat4(
	0.7599, 0.1423, 0.1905, 0.0,  //red channel
	0.2937, 0.6084, 0.2708, 0.0,  //green channel
	-0.0536, 0.2493, 0.5387, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9491  //alpha channel
); 

const mat4 GBA_Adobe = mat4(
	0.6759, 0.1163, 0.1803, 0.0,  //red channel
	0.3364, 0.6217, 0.2594, 0.0,  //green channel
	-0.0123, 0.2620, 0.5603, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9878   //alpha channel
);

const mat4 GBA_Rec2020 = mat4(
	0.6102, 0.1711, 0.1889, 0.0,  //red channel
	0.3551, 0.5898, 0.2768, 0.0,  //green channel
	0.0347, 0.2391, 0.5343, 0.0,  //blue channel
	0.0,  0.0,  0.0,   1.0  //alpha channel
);

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out mat4 profile;

void main()
{
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;

	if (color_mode == 1) profile = GBA_sRGB;
	else if (color_mode == 2) profile = GBA_DCI;
	else if (color_mode == 3) profile = GBA_Adobe;
	else if (color_mode == 4) profile = GBA_Rec2020;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in mat4 profile;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
	// bring out our stored luminance value
	float lum = profile[3].w;

	// our adjustments need to happen in linear gamma
	vec4 screen = pow(texture(Source, vTexCoord), vec4(target_gamma)).rgba;

	screen = clamp(screen * lum, 0.0, 1.0);
	screen = profile * screen;
	FragColor = pow(screen, vec4(1.0 / display_gamma));
}
