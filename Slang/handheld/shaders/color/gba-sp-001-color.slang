#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from both Gameboy Advance revision (cicra late 2001) and all Gameboy Advance SP that uses frontlit LCDs, aka AGS-001. This colorspace comes from Panasonic's GBA screen and uses 32-pin connector, and is the most common display you would fine for later GBA and all SP-001.

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

const mat4 SP0_sRGB = mat4(
	0.8774, 0.1186, 0.1772, 0.0,  //red channel
	0.2702, 0.6383, 0.2531, 0.0,  //green channel
	-0.1476, 0.2431, 0.5697, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.8714   //alpha channel
); 

const mat4 SP0_DCI = mat4(
	0.7427, 0.1438, 0.1849, 0.0,  //red channel
	0.3355, 0.6261, 0.2813, 0.0,  //green channel
	-0.0783, 0.2301, 0.5338, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9274   //alpha channel
);

const mat4 SP0_Adobe = mat4(
	0.6613, 0.1186, 0.1748, 0.0,  //red channel
	0.3750, 0.6383, 0.2690, 0.0,  //green channel
	-0.0363, 0.2431, 0.5562, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9650   //alpha channel
); 

const mat4 SP0_Rec2020 = mat4(
	0.5972, 0.1717, 0.1835, 0.0,  //red channel
	0.3907, 0.6085, 0.2873, 0.0,  //green channel
	0.0121, 0.2198, 0.5292, 0.0,  //blue channel
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

	if (color_mode == 1) profile = SP0_sRGB;
	else if (color_mode == 2) profile = SP0_DCI;
	else if (color_mode == 3) profile = SP0_Adobe;
	else if (color_mode == 4) profile = SP0_Rec2020;
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
