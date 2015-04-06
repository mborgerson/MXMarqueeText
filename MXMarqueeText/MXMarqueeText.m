// Copyright (c) 2015 Matt Borgerson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MXMarqueeText.h"

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAGradientLayer.h>
#import <QuartzCore/CATextLayer.h>

// Define the percentage points for the mask gradient
#define MASK_LEFT  0.05f
#define MASK_RIGHT 0.95f


@interface MXMarqueeText ()

@property CALayer *baseLayer;
@property CATextLayer *textLayer;
@property CAGradientLayer *maskLayer;
@property (nonatomic) bool shouldScroll;

@property NSTimer *scrollingTimer;

-(void)setupLayers;
-(void)setupScrollingTimer;

@end


@implementation MXMarqueeText

-(void)awakeFromNib
{
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (void)viewDidChangeBackingProperties
{
    self.textLayer.contentsScale = [[self window] backingScaleFactor];
}

-(void)setupLayers
{
    self.wantsLayer = YES;
    
    // Create Base Layer
    self.baseLayer = [CALayer layer];
    self.baseLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    self.baseLayer.frame = self.layer.bounds;
    [self.layer addSublayer:self.baseLayer];
    
    // Create Mask Layer
    self.maskLayer = [CAGradientLayer layer];
    self.maskLayer.anchorPoint = (CGPoint){ .x = 0.f, .y = 0.f };
    self.maskLayer.startPoint = CGPointMake(0.f, 0.5f);
    self.maskLayer.endPoint = CGPointMake(1.f, 0.5f);
    self.maskLayer.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.f],
                                                         [NSNumber numberWithFloat:MASK_LEFT],
                                                         [NSNumber numberWithFloat:MASK_RIGHT],
                                                         [NSNumber numberWithFloat:1.0f], nil];
    self.maskLayer.colors = [NSArray arrayWithObjects:(id)[[NSColor clearColor] CGColor],
                                                      (id)[[NSColor blackColor] CGColor],
                                                      (id)[[NSColor blackColor] CGColor],
                                                      (id)[[NSColor clearColor] CGColor], nil];
    
    self.maskLayer.frame = self.baseLayer.bounds;
    [self.baseLayer setMask:self.maskLayer];
    
    // Create Text Layer
    self.textLayer = [CATextLayer layer];
    self.textLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    self.textLayer.contentsScale = [[self window] backingScaleFactor];
    self.textLayer.anchorPoint = (CGPoint){ .x = 0.f, .y = 0.f };
    [self.baseLayer addSublayer:self.textLayer];
    
    // Setup default options
    self.scrollInterval = 2.f;
    self.pauseDuration = 1.f;
    self.speed = 50.f;
    self.fontSize = 14.f;
    self.foregroundColor = [NSColor blackColor];
    self.backgroundColor = [NSColor clearColor];
    self.shouldScroll = NO;
}

//
// Move text to the left, then back to the right.
//
-(void)animate
{
    CGPoint to;
    to.x = self.baseLayer.bounds.size.width-self.textLayer.bounds.size.width-self.baseLayer.bounds.size.width*(1.f-MASK_RIGHT);
    to.y = self.textLayer.position.y;
    
    CABasicAnimation *animationLeft = [CABasicAnimation animationWithKeyPath:@"position"];
    animationLeft.beginTime = 0.f;
    animationLeft.duration  = fmax(fabs(self.textLayer.position.x-to.x)/self.speed,1.f);
    animationLeft.fromValue = [NSValue valueWithPoint:self.textLayer.position];
    animationLeft.toValue   = [NSValue valueWithPoint:to];
    
    CABasicAnimation *animationPause = [CABasicAnimation animationWithKeyPath:@"position"];
    animationPause.beginTime = animationLeft.duration;
    animationPause.duration  = self.pauseDuration;
    animationPause.fromValue = animationLeft.toValue;
    animationPause.toValue   = animationLeft.toValue;
    
    CABasicAnimation *animationRight = [CABasicAnimation animationWithKeyPath:@"position"];
    animationRight.beginTime = animationLeft.duration+animationPause.duration;
    animationRight.duration  = animationLeft.duration;
    animationRight.fromValue = animationLeft.toValue;
    animationRight.toValue   = animationLeft.fromValue;
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = animationRight.duration+animationPause.duration+animationLeft.duration;
    group.animations = [NSArray arrayWithObjects:animationRight, animationPause, animationLeft, nil];
    group.delegate = self;
    [self.textLayer addAnimation:group forKey:@"position"];
}

-(void)setStringValue:(NSString *)aString
{
    if ([self.textLayer.string isEqualToString:aString]) return;
    [self.textLayer setString:aString];
    [self.textLayer layoutIfNeeded];
}

-(void)setForegroundColor:(NSColor *)foregroundColor
{
    [self.textLayer setForegroundColor:[foregroundColor CGColor]];
}

-(void)setBackgroundColor:(NSColor *)backgroundColor
{
    [self.baseLayer setBackgroundColor:[backgroundColor CGColor]];
}

-(void)setFont:(CFTypeRef)font
{
    [self.textLayer setFont:font];
}

-(void)setFontSize:(CGFloat)fontSize
{
    [self.textLayer setFontSize:fontSize];
}

-(void)layoutSublayersOfLayer:(CALayer *)layer
{
    [self.baseLayer layoutSublayers];
    
    // If the Text Layer has become larger than the base layer, left-justify it.
    if (self.textLayer.bounds.size.width > self.baseLayer.bounds.size.width*(MASK_RIGHT-MASK_LEFT))
    {
        CAConstraint *horizontalConstraint = [CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX scale:1.f offset:self.baseLayer.bounds.size.width*MASK_LEFT];
        CAConstraint *verticalConstraint = [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY];
        [self.textLayer setConstraints:[NSArray arrayWithObjects:verticalConstraint, horizontalConstraint, nil]];
        [self setShouldScroll:YES];
    } else {
        CAConstraint *horizontalConstraint = [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX];
        CAConstraint *verticalConstraint = [CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY];
        [self.textLayer setConstraints:[NSArray arrayWithObjects:verticalConstraint, horizontalConstraint, nil]];
        [self setShouldScroll:NO];
    }
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.shouldScroll && flag)
    {
        // Reset the scrolling timer
        [self setupScrollingTimer];
    }
    
}

-(void)setShouldScroll:(bool)shouldScroll
{
    _shouldScroll = shouldScroll;
    [self.textLayer removeAllAnimations];
    
    if (self.shouldScroll)
    {
        // Start the timer
        [self setupScrollingTimer];
    }
    else
    {
        // Invalidate the timer if it is set
        [self.scrollingTimer invalidate];
    }
}
    
-(void)setupScrollingTimer
{
    self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval
                                                           target:self
                                                         selector:@selector(animate)
                                                         userInfo:nil
                                                          repeats:NO];
}

@end