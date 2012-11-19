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

#import "Box.h"

#import "Physics.h"

@implementation Box {
	ccTime fixed_time;
	
	CCSprite *leftEye, *rightEye;
	CCSprite *mouth;
}

@synthesize lookAt = _lookAt;

@synthesize body = _body, shape = _shape;
@synthesize sprite = _sprite;

@synthesize chipmunkObjects = _chipmunkObjects;

-(id)init
{
	if((self = [super init])){
		cpFloat size = 30;
		cpFloat mass = 1.0;
		
		self.body = [ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)];
		self.body.data = self;
		
		self.shape = [ChipmunkPolyShape boxWithBody:self.body width:size height:size];
		self.shape.friction = 0.7;
		self.shape.layers = COLLISION_LAYERS_BOX;
		self.shape.data = self;
		
		self.chipmunkObjects = [NSArray arrayWithObjects:self.body, self.shape, nil];
		
		self.sprite = [CCPhysicsSprite spriteWithFile:@"BoxHappy.png"];
		self.sprite.chipmunkBody = self.body;
		
		leftEye = [[CCSprite alloc] initWithFile:@"Eye.png"];
		leftEye.position = ccp(10, 24);
		leftEye.scale = 0.5;
		[self.sprite addChild:leftEye];
		
		rightEye = [[CCSprite alloc] initWithFile:@"Eye.png"];
		rightEye.position = ccp(22, 24);
		rightEye.scale = 0.5;
		[self.sprite addChild:rightEye];
		
		self.lookAt = ccp(240, 0);
	}
	
	return self;
}

-(void)setLookAt:(CGPoint)lookAt
{
	leftEye.rotation -= CC_RADIANS_TO_DEGREES(ccpToAngle([leftEye convertToNodeSpaceAR:lookAt]));
	rightEye.rotation -= CC_RADIANS_TO_DEGREES(ccpToAngle([rightEye convertToNodeSpaceAR:lookAt]));
}

-(void)makeUpset;
{
	self.sprite.texture = [[CCTextureCache sharedTextureCache] addImage:@"BoxUpset.png"];
}

-(void)makeHappy;
{
	self.sprite.texture = [[CCTextureCache sharedTextureCache] addImage:@"BoxHappy.png"];
}

@end
