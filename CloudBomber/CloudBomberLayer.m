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

#import <CoreMotion/CoreMotion.h>

#import "CloudBomberLayer.h"
#import "ChipmunkAutoGeometry.h"
#import "ChipmunkGLRenderBufferSampler.h"
#import "ChipmunkDebugNode.h"

#import "Physics.h"

#import "Cloud.h"
#import "Missile.h"
#import "Box.h"

// Downsample the sample buffer so it can be read back and marched faster.
// Don't downsample too much though or you can end up with aliasing artifacts.
#define DOWNSAMPLE 3.0

static const ccColor4B SKY_COLOR = {30, 66, 78, 255};


enum Z_ORDER {
	Z_SKY,
	Z_TERRAIN,
	Z_CRATES,
	Z_MISSILE,
	Z_CLOUD,
	Z_EFFECTS,
	Z_DEBUG,
	Z_MENU,
};


#define WeakSelf(__var__) __unsafe_unretained typeof(*self) *__var__ = self


@interface CloudBomberLayer()

-(void)updateTerrain;

@end


@implementation CloudBomberLayer {
	CMMotionManager *motionManager;
	ChipmunkSpace *space;
	
	CCLayerColor *skyLayer;
	CCSprite *terrain;
	Cloud *cloud;
	
	CCRenderTexture *terrainRenderTexture;
	ChipmunkGLRenderBufferSampler *sampler;
	
	NSMutableArray * segments;
	
	Missile *currentMissile;
	NSMutableArray *missiles;
	NSMutableArray *boxes;
	
	NSDictionary *particlesDef;
}

+(CCScene *)scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [self node]];
	
	return scene;
}

-(id)init
{
	if((self = [super init])){
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		// Setup the space
		space = [[ChipmunkSpace alloc] init];
		space.gravity = cpv(0.0f, -400.0f);
		
		CGRect rect = {CGPointZero, winSize};
		[space addBounds:rect thickness:20.0f elasticity:0.5f friction:1.0f layers:COLLISION_LAYERS_TERRAIN group:CP_NO_GROUP collisionType:PhysicsIdentifier(COLLISION_TYPE_TERRAIN)];
		
		// Add a collision handler to blow up the missiles when they hit the ground.
		[space addCollisionHandler:self typeA:PhysicsIdentifier(COLLISION_TYPE_TERRAIN) typeB:[Missile class] begin:@selector(missileExplode:space:) preSolve:nil postSolve:nil separate:nil];
		
		// Color layer for the sky
		skyLayer = [CCLayerColor layerWithColor:SKY_COLOR];
		[self addChild:skyLayer z:Z_SKY];
													
		// Make a CCSprite for the terrain.
		terrain = [[CCSprite alloc] initWithFile:@"Terrain.png"];
		terrain.anchorPoint = CGPointZero;
		
		// Create the render texture for displaying the terrain on the screen.
		// We'll be punching holes in the alpha of this texture.
		CGSize pixels = [CCDirector sharedDirector].winSizeInPixels;
		terrainRenderTexture = [[CCRenderTexture alloc] initWithWidth:pixels.width height:pixels.height pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
		terrainRenderTexture.sprite.anchorPoint = ccp(0, 1);
		[self addChild:terrainRenderTexture z:Z_TERRAIN];
		
		// Create a render texture to back the ChipmunkCCRenderTextureSampler
		// We don't need or want full per-pixel resolution for this one.
//		terrainTextureSampler = [[CCRenderTexture alloc] initWithWidth:winSize.width/DOWNSAMPLE height:winSize.height/DOWNSAMPLE pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
		sampler = [[ChipmunkGLRenderBufferSampler alloc] initWithWidth:winSize.width/DOWNSAMPLE height:winSize.height/DOWNSAMPLE];
		sampler.outputRect = cpBBNew(0, 0, 480, 320);
		[self updateTerrain];
		
		missiles = [[NSMutableArray alloc] init];
		boxes = [[NSMutableArray alloc] init];
		particlesDef = [NSDictionary dictionaryWithContentsOfFile:[[CCFileUtils sharedFileUtils] fullPathFromRelativePath:@"kaboom.plist"]];
		
		// Add a cloud
		cloud = [[Cloud alloc] init];
		[self addChild:cloud z:Z_CLOUD];
		
		// Add a bunch of boxes.
		for(int i=0; i<100; i++){
			Box *box = [[Box alloc] init];
			box.body.pos = cpv(CCRANDOM_0_1()*winSize.width, CCRANDOM_0_1()*winSize.height);
			box.body.angle = CCRANDOM_0_1()*2.0*M_PI;
			
			// Check that it's not underground, and make sure that it's not overlapping an existing shape.
			if([sampler sample:box.body.pos] < 0.5 && ![space shapeTest:box.shape]){
				[space add:box];
				[self addChild:box.sprite z:Z_CRATES];
				[boxes addObject:box];
			}
		}
		
		// Add a ChipmunkDebugNode to draw the space.
		ChipmunkDebugNode *debugNode = [ChipmunkDebugNode debugNodeForChipmunkSpace:space];
		[self addChild:debugNode z:Z_DEBUG];
		debugNode.visible = FALSE;
		
		// Show some menu buttons.
		CCMenuItemLabel *reset = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Reset" fontName:@"Helvetica" fontSize:20] block:^(id sender){
			[[CCDirector sharedDirector] replaceScene:[[CloudBomberLayer class] scene]];
		}];
		reset.position = ccp(50, 300);
		
		CCMenuItemLabel *showDebug = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Show Debug" fontName:@"Helvetica" fontSize:20] block:^(id sender){
			debugNode.visible ^= TRUE;
		}];
		showDebug.position = ccp(400, 300);
		
		CCMenu *menu = [CCMenu menuWithItems:reset, showDebug, nil];
		menu.position = CGPointZero;
		[self addChild:menu z:Z_MENU];
		
		self.isTouchEnabled = TRUE;
	}
	
	return self;
}

-(void)onEnter
{
	motionManager = [[CMMotionManager alloc] init];
	motionManager.accelerometerUpdateInterval = [CCDirector sharedDirector].animationInterval;
	[motionManager startAccelerometerUpdates];
	
	[self scheduleUpdate];
	[super onEnter];
}

-(void)onExit
{
	[motionManager stopAccelerometerUpdates];
	motionManager = nil;
	
	[super onExit];
}

-(void)update:(ccTime)dt
{
#if TARGET_IPHONE_SIMULATOR
	CMAcceleration gravity = {-1, 0, 0};
#else
	CMAcceleration gravity = motionManager.accelerometerData.acceleration;
#endif
	
	space.gravity = cpvmult(cpv(-gravity.y, gravity.x), 400.0f);
	
	// Update the physics
	ccTime fixed_dt = [CCDirector sharedDirector].animationInterval;
	[space step:fixed_dt];
	
	// Make the boxes look at the cloud or current missile.
	cpVect lookAt = (currentMissile ? currentMissile.body.pos : cloud.position);
	for(Box *box in boxes){
		box.lookAt = lookAt;
	}
}

-(void)updateTerrain;
{
	// TODO should split this up.
	// glReadPixels to a PBO now, then map the buffer after rendering the frame.
	
	// Update the render texture with any new holes that were added.
	[terrainRenderTexture beginWithClear:0 g:0 b:0 a:0]; {
		[terrain visit];
	} [terrainRenderTexture end];
	
	// Render the terrain on the GPU and pull them back to the CPU to be marched later.
	[sampler renderInto:^{[terrain visit];}];
	
	// Remove the old segments
	for(ChipmunkShape *seg in segments) [space remove:seg];
	
	// Add all new segments by marching the sampler and extracting the geometry
	segments = [NSMutableArray array];
	for(ChipmunkPolyline * line in [sampler marchAllWithBorder:FALSE hard:FALSE]){
		// Simplify the line data to ignore details smaller than a pixel.
		ChipmunkPolyline * simplified = [line simplifyCurves:1.0f];
		
		// Ignore a loop if it has a small amount of area.
		// This avoids tiny little floating chunks of dirt.
		if(simplified.isLooped && simplified.area < 100) continue;
		
		for(int i=0; i<simplified.count-1; i++){
			cpVect a = simplified.verts[i];
			cpVect b = simplified.verts[i+1];
			
			ChipmunkShape *seg = [ChipmunkSegmentShape segmentWithBody:space.staticBody from:a to:b radius:1.0f];
			seg.friction = 1.0;
			seg.layers = COLLISION_LAYERS_TERRAIN;
			seg.collisionType = PhysicsIdentifier(COLLISION_TYPE_TERRAIN);
			
			[segments addObject:seg];
			[space add:seg];
		}
	}
	
}

-(void)scheduleBlockOnce:(void (^)(void))block delay:(ccTime)delay
{
	// There really needs to be a 
	[self.scheduler scheduleSelector:@selector(invoke) forTarget:[block copy] interval:0.0 paused:FALSE repeat:1 delay:delay];
}

-(void)applyExplosionImpulses:(cpVect)origin
{
	const cpFloat splash = 100.0;
	const cpFloat strength = 400.0;
	
	// Query for all the boxes near the explosion's origin.
	for(ChipmunkNearestPointQueryInfo *info in [space nearestPointQueryAll:origin maxDistance:splash layers:COLLISION_RULE_BOX_ONLY group:CP_NO_GROUP]){
		ChipmunkBody *body = info.shape.body;
		cpVect point = info.point;
		
		// Use the nearest point to calculate the impulse to apply.
		// This makes for a pretty good approximation.
		cpFloat intensity = 1.0 - cpvdist(point, origin)/splash;
		cpVect impulse = cpvmult(cpvnormalize(cpvsub(point, origin)), strength*intensity);
		[body applyImpulse:impulse offset:cpvsub(point, body.pos)];
		
		// Play with the boxes' emotions.
		Box *box = body.data;
		[box makeUpset];
		[self scheduleBlockOnce:^{[box makeHappy];} delay:intensity*1.0];
	}
}

-(void)addExplosionEffects:(cpVect)position
{
	// Flash the sky
	[skyLayer setColor:ccc3(255, 255, 255)];
	[skyLayer runAction:[CCTintTo actionWithDuration:0.1 red:SKY_COLOR.r green:SKY_COLOR.g blue:SKY_COLOR.b]];
	
	// Add a particle effect
	CCParticleSystem *particles = [[CCParticleSystemQuad alloc] initWithDictionary:particlesDef];
	particles.position = position;
	particles.autoRemoveOnFinish = TRUE;
	[self addChild:particles z:Z_EFFECTS];
	
	// Add a scorch mark to the terrain texture and punch a hole in the alpha.
	CCSprite *scorch = [CCSprite spriteWithFile:@"Scorch.png"];
	scorch.position = position;
	scorch.rotation = 360.0*CCRANDOM_0_1();
	scorch.scale = 1.0;
	scorch.blendFunc = (ccBlendFunc){GL_ZERO, GL_SRC_COLOR};
	[terrain addChild:scorch];
	
	// Update the render textures and sampler
	[self updateTerrain];
}

-(BOOL)missileExplode:(cpArbiter *)arb space:(ChipmunkSpace *)ignored
{
	CHIPMUNK_ARBITER_GET_BODIES(arb, terrainBody, missileBody);
	Missile *missile = missileBody.data;
	cpVect contactPoint = cpArbiterGetPoint(arb, 0);
	
	// Explosion impulses should be applied during the pre-solve phase.
	// If the impulses are applied after the solver in the post-step block below then the
	// solver won't have a chance to correct the forces before the next position update.
	// Ideally this should be put in the post-step block below so it doesn't get triggered multiple times,
	// but it doesn't really matter in this case.
	[self applyExplosionImpulses:contactPoint];
	
	// Perform these in a post-step block so that they won't end up running multiple times.
	// That could happen if the missile collides with multiple ground shapes simultaneously.
	WeakSelf(_self);
	[space addPostStepBlock:^{
		if(_self->currentMissile == missile) _self->currentMissile = nil;
		
		[_self->missiles removeObject:missile];
		[_self removeChild:missile.sprite cleanup:TRUE];
		[_self->space remove:missile];
		
		[_self addExplosionEffects:contactPoint];
	} key:missile];
	
	return FALSE;
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSAssert(touches.count == 1, @"Touches should be 1!");
	
	UITouch *touch = touches.anyObject;
	currentMissile = [[Missile alloc] initWithPosition:cloud.position andTarget:[self convertTouchToNodeSpace:touch]];
	[missiles addObject:currentMissile];
	
	[self addChild:currentMissile.sprite z:Z_MISSILE];
	[space add:currentMissile];
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint location = [self convertTouchToNodeSpace:touches.anyObject];
	if(currentMissile) currentMissile.target = location;
	
	cloud.lookAt = location;
}

-(void)ccTouchesEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(currentMissile){
		currentMissile.isTracking = FALSE;
		currentMissile = nil;
	}
	
	cloud.lookAt = ccp(240, 0);
}

@end
