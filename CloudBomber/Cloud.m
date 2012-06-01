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

#import "Cloud.h"


@implementation Cloud {
	ccTime fixed_time;
	
	CCSprite *leftEye, *rightEye;
}

@synthesize lookAt = _lookAt;

-(id)init
{
	if((self = [super initWithFile:@"Cloud.png"])){
		self.position = ccp(240, 280);
		
		leftEye = [[CCSprite alloc] initWithFile:@"Eye.png"];
		leftEye.position = ccp(40, 37);
		[self addChild:leftEye];
		
		rightEye = [[CCSprite alloc] initWithFile:@"Eye.png"];
		rightEye.position = ccp(67, 37);
		[self addChild:rightEye];
		
		self.lookAt = ccp(240, 0);
		
		CCSprite *eyeBrow = [CCSprite spriteWithFile:@"EyeBrow.png"];
		eyeBrow.position = ccp(51, 45);
		[self addChild:eyeBrow];
		
		[self scheduleUpdate];
	}
	
	return self;
}

-(void) update:(ccTime) dt
{
	ccTime fixed_dt = [CCDirector sharedDirector].animationInterval;
	fixed_time += fixed_dt;
	
	self.position = ccp(240.0 + 200.0*sinf(fixed_time/3.0), self.position.y);
	
	leftEye.rotation -= CC_RADIANS_TO_DEGREES(ccpToAngle([leftEye convertToNodeSpaceAR:_lookAt]));
	rightEye.rotation -= CC_RADIANS_TO_DEGREES(ccpToAngle([rightEye convertToNodeSpaceAR:_lookAt]));
}

@end
