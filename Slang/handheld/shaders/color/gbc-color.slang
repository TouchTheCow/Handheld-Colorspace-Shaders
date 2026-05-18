#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from all Gameboy Color revisions and all manufactured by Sharp.

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

const mat4 GBC_sRGB = mat4(
	0.8944, 0.1091, 0.1447, 0.0,  //red channel
	0.2179, 0.6312, 0.2837, 0.0,  //green channel
	-0.1125, 0.2597, 0.5716, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.8989   //alpha channel
); 

const mat4 GBC_DCI = mat4(
	0.7551, 0.1352, 0.1549, 0.0,  //red channel
	0.2913, 0.6174, 0.3077, 0.0,  //green channel
	-0.0464, 0.2474, 0.5374, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9557   //alpha channel
); 

const mat4 GBC_Adobe = mat4(
	0.6708, 0.1091, 0.1432, 0.0,  //red channel
	0.3357, 0.6312, 0.2980, 0.0,  //green channel
	-0.0065, 0.2597, 0.5588, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9935   //alpha channel
);

const mat4 GBC_Rec2020 = mat4(
	0.6034, 0.1638, 0.1539, 0.0,  //red channel
	0.3569, 0.5987, 0.3132, 0.0,  //green channel
	0.0397, 0.2375, 0.5329, 0.0,  //blue channel
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

	if (color_mode == 1) profile = GBC_sRGB;
	else if (color_mode == 2) profile = GBC_DCI;
	else if (color_mode == 3) profile = GBC_Adobe;
	else if (color_mode == 4) profile = GBC_Rec2020;
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
