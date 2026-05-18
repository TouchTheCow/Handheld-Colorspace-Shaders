#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from a Gameboy Micro (OXY-001).

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

const mat4 GBM_sRGB = mat4(
	0.7702, 0.1001, 0.1123, 0.0,  //red channel
	0.3253, 0.6837, 0.0990, 0.0,  //green channel
	-0.0955, 0.2162, 0.7887, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9128   //alpha channel
); 

const mat4 GBM_DCI = mat4(
	0.6513, 0.1223, 0.1227, 0.0,  //red channel
	0.3889, 0.6718, 0.1452, 0.0,  //green channel
	-0.0402, 0.2059, 0.7321, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9614   //alpha channel
); 

const mat4 GBM_Adobe = mat4(
	0.5793, 0.1001, 0.1118, 0.0,  //red channel
	0.4274, 0.6837, 0.1230, 0.0,  //green channel
	-0.0067, 0.2162, 0.7652, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9933   //alpha channel
);

const mat4 GBM_Rec2020 = mat4(
	0.5211, 0.1465, 0.1220, 0.0,  //red channel
	0.4335, 0.6523, 0.1541, 0.0,  //green channel
	0.0454, 0.2012, 0.7239, 0.0,  //blue channel
	0.0,  0.0,  0.0,  1.0   //alpha channel
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

	if (color_mode == 1) profile = GBM_sRGB;
	else if (color_mode == 2) profile = GBM_DCI;
	else if (color_mode == 3) profile = GBM_Adobe;
	else if (color_mode == 4) profile = GBM_Rec2020;
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
