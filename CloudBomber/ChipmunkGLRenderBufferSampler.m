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

#import "ChipmunkGLRenderBufferSampler.h"

@implementation ChipmunkGLRenderBufferSampler

-(id)initWithWidth:(NSUInteger)width height:(NSUInteger)height;
{
	int stride = width*4;
	NSMutableData *pixelData = [NSMutableData dataWithLength:stride*height];
	
	if((self = [self initWithWidth:width height:height stride:stride bytesPerPixel:4 component:3 flip:FALSE pixelData:pixelData])){
		GLint oldFBO, oldRBO;
		glGetIntegerv(GL_FRAMEBUFFER_BINDING, &oldFBO);
		glGetIntegerv(GL_RENDERBUFFER_BINDING, &oldRBO);

		glGenFramebuffers(1, &_fbo);
		glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
		
		glGenRenderbuffers(1, &_rbo);
		glBindRenderbuffer(GL_RENDERBUFFER, _rbo);
		
		glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _rbo);
		NSAssert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, @"Failed to create FBO for offscreen rendering.");

		glBindFramebuffer(GL_FRAMEBUFFER, oldFBO);
		glBindRenderbuffer(GL_RENDERBUFFER, oldRBO);
	}
	
	return self;
}

-(void)dealloc
{
	glDeleteFramebuffers(1, &_fbo);
	glDeleteRenderbuffers(1, &_rbo);
		
	[super dealloc];
}

-(void)renderInto:(void (^)(void))block;
{
	GLint viewport[4];
	glGetIntegerv(GL_VIEWPORT, viewport);
	glViewport(0, 0, self.width, self.height);

	GLint oldFBO;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING, &oldFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, _fbo);

	GLfloat	clearColor[4];
	glGetFloatv(GL_COLOR_CLEAR_VALUE, clearColor);
	glClearColor(0, 0, 0, 0);
	
	glClear(GL_COLOR_BUFFER_BIT);
	block();
	glReadPixels(0, 0, self.width, self.height, GL_RGBA, GL_UNSIGNED_BYTE, [(NSMutableData *)self.pixelData mutableBytes]);
	
	glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
	glBindFramebuffer(GL_FRAMEBUFFER, oldFBO);
	glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
}

@end
