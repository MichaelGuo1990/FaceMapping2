//--------------------------------------------------------------------------------------
// Copyright 2014 Intel Corporation
// All Rights Reserved
//
// Permission is granted to use, copy, distribute and prepare derivative works of this
// software for any purpose and without fee, provided, that the above copyright notice
// and this statement appear in all copies.  Intel makes no representations about the
// suitability of this software for any purpose.  THIS SOFTWARE IS PROVIDED "AS IS."
// INTEL SPECIFICALLY DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, AND ALL LIABILITY,
// INCLUDING CONSEQUENTIAL AND OTHER INDIRECT DAMAGES, FOR THE USE OF THIS SOFTWARE,
// INCLUDING LIABILITY FOR INFRINGEMENT OF ANY PROPRIETARY RIGHTS, AND INCLUDING THE
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  Intel does not
// assume any responsibility for any errors which may appear in this software nor any
// responsibility to update it.
//--------------------------------------------------------------------------------------
// Generated by ShaderGenerator.exe version 0.13
//--------------------------------------------------------------------------------------
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
// -------------------------------------
layout (std140, row_major) uniform cbPerModelValues
{
   mat4 World;
   mat4 NormalMatrix;
   mat4 WorldViewProjection;
   mat4 InverseWorld;
   mat4 LightWorldViewProjection;
   vec4 BoundingBoxCenterWorldSpace;
   vec4 BoundingBoxHalfWorldSpace;
   vec4 BoundingBoxCenterObjectSpace;
   vec4 BoundingBoxHalfObjectSpace;
};

// -------------------------------------
layout (std140, row_major) uniform cbPerFrameValues
{
   mat4  View;
   mat4  InverseView;
   mat4  Projection;
   mat4  ViewProjection;
   vec4  AmbientColor;
   vec4  LightColor;
   vec4  LightDirection;
   vec4  EyePosition;
   vec4  TotalTimeInSeconds;
};

layout (std140, row_major) uniform cbExternals
{
	vec4 gSurfaceColor;
	float gSpecExpon;
	float Kd;
	float Ks;
};

#ifdef GLSL_VERTEX_SHADER

#define POSITION  0
#define NORMAL    1
#define BINORMAL  2
#define TANGENT   3
#define COLOR   4
#define TEXCOORD0 5
// -------------------------------------
layout (location = POSITION)  in vec3 Position; // Projected position
layout (location = NORMAL)    in vec3 Normal;
layout (location = TEXCOORD0) in vec2 UV0;
// -------------------------------------
out vec4 outPosition;
out vec3 outNormal;
out vec2 outUV0;
out vec3 outWorldPosition; // Object space position 
out vec3 outLightUV;
#endif //GLSL_VERTEX_SHADER
#ifdef GLSL_FRAGMENT_SHADER
// -------------------------------------
in vec4 outPosition;
in vec3 outNormal;
in vec2 outUV0;
in vec3 outWorldPosition; // Object space position 
in vec3 outLightUV;
// -------------------------------------
uniform sampler2D texture0;
uniform sampler2DShadow _Shadow;
// -------------------------------------
vec4 DIFFUSE( )
{
    //return vec4(0.5, 0.5, 0.5, 1.0);
    return texture(texture0,(((outUV0)) *(10.0)) );
}

// -------------------------------------
vec4 SPECULAR( )
{
    return vec3(1, 1, 1).xyzz;
}

float ComputeShadowAmount( )
{   
	vec3  lightUV = outLightUV.xyz;
    lightUV.xyz = lightUV.xyz * 0.5 + 0.5; // TODO: Move to matrix?

// works on nexus
	float depth_light = textureProj(_Shadow,vec4(lightUV,1.0));
	return 1.0-depth_light;

// works on baytrail and desktop
	//vec4  shadowAmount = textureGather(_Shadow, lightUV.xy, lightUV.z);
    //return 1.0-(shadowAmount.x+shadowAmount.y+shadowAmount.z+shadowAmount.w)*.25;
}



// -------------------------------------
#endif //GLSL_FRAGMENT_SHADER

#ifdef GLSL_VERTEX_SHADER
// -------------------------------------
void main( )
{

    outPosition      = vec4( Position, 1.0) * WorldViewProjection;
    outWorldPosition = (vec4( Position, 1.0) * World ).xyz;

    // TODO: transform the light into object space instead of the normal into world space
    outNormal   = (vec4(Normal, 1.0) * World).xyz;
	outUV0 = UV0;
	outLightUV = (vec4( Position, 1.0) * LightWorldViewProjection).xyz;

    gl_Position = outPosition;
}

#endif //GLSL_VERTEX_SHADER

#ifdef GLSL_FRAGMENT_SHADER
out vec4 fragColor;
// -------------------------------------
void main( )
{
    vec4 result = vec4(0,0,0,1);

    vec3 normal = normalize(outNormal);

    // Specular-related computation
    vec3 eyeDirection  = normalize(outWorldPosition - EyePosition.xyz);
    vec3 Reflection    = reflect( eyeDirection, normal );
    float  shadowAmount = ComputeShadowAmount();

	vec3 diffuseColor = DIFFUSE().rgb * gSurfaceColor.rgb;
    // Ambient-related computation
    vec3 ambient = AmbientColor.rgb * diffuseColor;
    result.xyz +=  ambient;
    
	
    // Diffuse-related computation
    vec3 lightDirection = -LightDirection.xyz;
	float  nDotL = max( 0.0 ,dot( normal.xyz, lightDirection.xyz ) );
    vec3 diffuse = LightColor.rgb * nDotL * shadowAmount  * diffuseColor * Kd;
    result.xyz += diffuse;

    float  rDotL	= max(0.0 ,dot( Reflection.xyz, lightDirection.xyz ));
	vec3 specular	= pow(rDotL,  gSpecExpon ) * shadowAmount * SPECULAR().rgb * Ks * LightColor.rgb;
    result.xyz	   += nDotL > 0.0 ? specular : vec3(0);
	
    fragColor = result;
}

#endif //GLSL_FRAGMENT_SHADER
