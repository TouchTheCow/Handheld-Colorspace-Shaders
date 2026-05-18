#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from a Gameboy SP 101 (backlit version), aka AGS-101.

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

const mat4 SP1_sRGB = mat4(
	1.0050, 0.0412, -0.0094, 0.0,  //red channel
	0.0722, 0.8738, -0.0546, 0.0,  //green channel
	-0.0772, 0.0850, 1.0640, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9283   //alpha channel
); 

const mat4 SP1_DCI = mat4(
	0.8339, 0.0732, 0.0116, 0.0,  //red channel
	0.2145, 0.8472, 0.0148, 0.0,  //green channel
	-0.0484, 0.0796, 0.9736, 0.0,  //blue channel
	0.0,   0.0,   0.0,   0.9538  //alpha channel
); 

const mat4 SP1_Adobe = mat4(
	0.7305, 0.0412, -0.0073, 0.0,  //red channel
	0.3005, 0.8738, -0.0164, 0.0,  //green channel
	-0.0310, 0.0850, 1.0237, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9699   //alpha channel
);

const mat4 SP1_Rec2020 = mat4(
	0.6438, 0.1073, 0.0117, 0.0,  //red channel
	0.3306, 0.8078, 0.0292, 0.0,  //green channel
	0.0256, 0.0849, 0.9591, 0.0,  //blue channel
	0.0,   0.0,   0.0,   1.0  //alpha channel
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

	if (color_mode == 1) profile = SP1_sRGB;
	else if (color_mode == 2) profile = SP1_DCI;
	else if (color_mode == 3) profile = SP1_Adobe;
	else if (color_mode == 4) profile = SP1_Rec2020;
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
