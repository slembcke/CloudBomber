/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "cocos2d.h"
#import "ChipmunkImageSampler.h"

/*
	This class is a little hacked together, but works just dandy.
	By calling the render method, you can render into it just like a
	CCRenderTexture and the drawing result ends up in the sampler.
	Unlike a CCRenderTexture, it doesn't change the projection.
	
	Also, it provides no sort of dirty rectangle management.
	The entire framebuffer is synced each time.
	
	TODO I can make this more efficient later by reading into a PBO then
	mapping the PBO only when the the data is accessed.
*/

@interface ChipmunkGLRenderBufferSampler : ChipmunkBitmapSampler {
@private
	GLuint _fbo, _rbo;
}

-(id)initWithWidth:(NSUInteger)width height:(NSUInteger)height;

-(void)renderInto:(void (^)(void))block;

@end
