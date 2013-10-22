/*
     File: reflect.fsh
 Abstract: The fragment shader for reflection rendering.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#ifdef GL_ES
precision highp float;
#endif


const vec3 Xunitvec = vec3(1.0, 0.0, 0.0);
const vec3 Yunitvec = vec3(0.0, 1.0, 0.0);

// Color of tint to apply
const vec4 tintColor = vec4(0.0, 0.0, 1.0, 1.0);

// Amount of tint to apply
const float tintFactor = 0.2;

varying vec3  varNormal;
varying vec3  varEyeDir;

uniform sampler2D diffuseTexture;

void main (void)
{
	// Compute reflection vector
    
    vec3 reflectDir = reflect(varEyeDir, varNormal);

    // Compute altitude and azimuth angles

    vec2 texcoord;

    texcoord.y = dot(normalize(reflectDir), Yunitvec);
    reflectDir.y = 0.0;
    texcoord.x = dot(normalize(reflectDir), Xunitvec) * 0.5;

    // Translate index values into proper range

    if (reflectDir.z >= 0.0)
        texcoord = (texcoord + 1.0) * 0.5;
    else
    {
        texcoord.t = (texcoord.t + 1.0) * 0.5;
        texcoord.s = (-texcoord.s) * 0.5 + 1.0;
    }
    
  
	vec4 texColor = texture2D(diffuseTexture, texcoord);
	  
    // Do a lookup into the environment map.

    gl_FragColor = mix(texColor, tintColor, tintFactor);
}