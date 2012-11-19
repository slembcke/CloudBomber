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

#import "Missile.h"

#import "Physics.h"

#define MISSILE_SIZE 32.0
#define MISSILE_SPEED 200.0
#define MISSILE_TURN_SPEED 6.0


@implementation Missile

@synthesize body = _body;
@synthesize chipmunkObjects = _chipmunkObjects;

@synthesize isTracking = _isTracking;
@synthesize target = _target;

@synthesize sprite = _sprite;

static cpVect
Turn(cpVect v1, cpVect v2, cpFloat limit)
{
	// Angle between the two vectors
	cpFloat angle = cpfacos(cpfclamp01(cpvdot(cpvnormalize(v1), cpvnormalize(v2))));
	if(angle){
		// Performs an nlerp() between two direction vectors.
		cpVect direction = cpvnormalize(cpvlerp(v1, v2, cpfmin(limit, angle)/angle));
		return cpvmult(direction, MISSILE_SPEED);
	} else {
		return v1;
	}
}

// Custom velocity update function for steering the missiles
static void
MissileVelocityUpdate(cpBody *cBody, cpVect gravity, cpFloat damping, cpFloat dt)
{
	ChipmunkBody *body = [ChipmunkBody bodyFromCPBody:cBody];
	Missile *missile = body.data;
	
	if(missile.isTracking){
		cpVect targetVelocity = cpvmult(cpvnormalize(cpvsub(missile.target, body.pos)), MISSILE_SPEED);
		body.vel = Turn(body.vel, targetVelocity, MISSILE_TURN_SPEED*dt);
	}
	
	body.angle = cpvtoangle(body.vel) - M_PI/2.0;
}

-(id)initWithPosition:(cpVect)pos andTarget:(cpVect)target
{
	if((self = [super init])){
		self.isTracking = TRUE;
		self.target = target;
		
		ChipmunkBody *body = self.body = [ChipmunkBody bodyWithMass:1.0 andMoment:INFINITY];
		body.pos = pos;
		body.vel = cpvmult(cpvnormalize(cpvsub(target, pos)), MISSILE_SPEED);
		body.body->velocity_func = MissileVelocityUpdate;
		body.data = self;
		
		ChipmunkShape *shape = [ChipmunkCircleShape circleWithBody:body radius:MISSILE_SIZE/2.0 offset:cpvzero];
		shape.data = self;
		shape.group = PhysicsIdentifier(COLLISION_GROUP_MISSILE_BOX);
		shape.layers = COLLISION_LAYERS_MISSILE;
		shape.collisionType = [Missile class];
		
		self.chipmunkObjects = [NSArray arrayWithObjects:body, shape, nil];
		
		self.sprite = [CCPhysicsSprite spriteWithFile:@"Missile.png"];
		self.sprite.chipmunkBody = self.body;
	}
	
	return self;
}

@end
