#import "CCActivityIndicatorView.h"

#define NUMBER_OF_SCALE_DOT 15
#define NUMBER_OF_LEADING_DOT 3
#define DURATION_BASE 0.7

@interface CCActivityIndicatorView ()

@property (strong, nonatomic) CAReplicatorLayer *replicatorLayer;
@property (strong, nonatomic) CALayer *indicatorCALayer;
@property (strong, nonatomic) CAShapeLayer *indicatorCAShapeLayer;
@property (strong, nonatomic) UIColor *updatedColor;

@property CCIndicatorType currentTpye;

@end

@implementation CCActivityIndicatorView

#pragma mark - custom accessors
- (void)setBackColor:(UIColor *)backColor {
    if (backColor !=self.backgroundColor) {
        self.backgroundColor = backColor;
    }
}

- (void)setBorderColor:(UIColor *)borderColor {
    if (borderColor.CGColor != self.layer.borderColor) {
        self.layer.borderColor = borderColor.CGColor;
    }
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    if (borderWidth != self.layer.borderWidth) {
        self.layer.borderWidth = borderWidth;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    if (cornerRadius != self.layer.cornerRadius) {
        self.layer.cornerRadius = cornerRadius;
    }
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
        self.updatedColor = indicatorColor;
}

#pragma mark - public methods
- (void)showWithType:(CCIndicatorType)type {
    if (!self.superview) {
        [[[UIApplication sharedApplication].windows lastObject] addSubview:self];
        [self.superview bringSubviewToFront:self];
        
        [self initializeReplicatorLayer];
        [self initializeIndicatoeLayerWithType:type];
        self.currentTpye = type;
        
        // chage the indicator color if user do not use the default color
        if (self.indicatorCALayer && self.updatedColor) {
            self.indicatorCALayer.backgroundColor = self.updatedColor.CGColor;
        } else if (self.indicatorCAShapeLayer && self.updatedColor) {
            self.indicatorCAShapeLayer.strokeColor = self.updatedColor.CGColor;
        }
        
        [self addAppearAnimation];
        
        if (self.isTheOnlyActiveView) {
            for (UIView *view in self.superview.subviews) {
                view.userInteractionEnabled = NO;
            }
        }
    }
}

- (void)show {
    [self showWithType:CCIndicatorTypeScalingDots];
}

- (void)dismiss {
    if (self.superview) {
        [self addDisappearAnimation];
        
        if (self.isTheOnlyActiveView) {
            for (UIView *view in self.superview.subviews) {
                view.userInteractionEnabled = YES;
            }
        }
    }
}

#pragma mark - life cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - initialization
- (instancetype)init {
    self = [super init];
    
    if (self) {
        CGRect bounds = [UIScreen mainScreen].bounds;
        CGFloat boundsWdith = bounds.size.width;
        CGFloat length = boundsWdith/6;
        self.frame = CGRectMake(-2*length, -2*length, length, length);
        self.alpha = 0.7;
        self.backgroundColor = [UIColor blackColor];
        self.layer.cornerRadius = 10.0;
        
        self.isTheOnlyActiveView = YES;
    
        self.appearAnimationType = CCIndicatorAppearAnimationTypeFadeIn;
        self.disappearAnimationType = CCIndicatorDisappearAnimationTypeFadeOut;
        
        [self addNotificationObserver];
    }
    
    return self;
}

- (void)addNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAnimation) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)initializeReplicatorLayer {
    self.layer.sublayers = nil;
    
    self.replicatorLayer = [[CAReplicatorLayer alloc] init];
    self.replicatorLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.replicatorLayer.backgroundColor = [UIColor clearColor].CGColor;
    
    [self.layer addSublayer:self.replicatorLayer];
}

- (void)initializeIndicatoeLayerWithType:(CCIndicatorType)type {
    self.replicatorLayer.sublayers = nil;
    
    switch (type) {
        case CCIndicatorTypeScalingDots:
            [self initializeScalingDots];
            break;
            
        case CCIndicatorTypeLeadingDots:
            [self initializeLeadingDots];
            break;
            
        case CCIndicatorTypeCircle:
            [self initializeCircle];
            break;
            
        case CCIndicatorTypeArc:
            [self initializeArc];
            break;
    }
}

- (void)initializeScalingDots {
    CGFloat length = self.frame.size.width*18/200;
    
    self.indicatorCALayer = [[CALayer alloc] init];
    self.indicatorCALayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.indicatorCALayer.frame = CGRectMake(0, 0, length, length);
    self.indicatorCALayer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/5);
    self.indicatorCALayer.cornerRadius = length/2;
    self.indicatorCALayer.transform = CATransform3DMakeScale(0.01, 0.01, 0.01);
    
    self.replicatorLayer.instanceCount = NUMBER_OF_SCALE_DOT;
    self.replicatorLayer.instanceDelay = DURATION_BASE*1.2/self.replicatorLayer.instanceCount;
    CGFloat angle = 2*M_PI/NUMBER_OF_SCALE_DOT;
    self.replicatorLayer.instanceTransform = CATransform3DMakeRotation(angle, 0.0, 0.0, 0.1);
    
    [self.replicatorLayer addSublayer:self.indicatorCALayer];
}

- (void)initializeLeadingDots {
    CGFloat length = self.frame.size.width*18/200;

    self.indicatorCALayer = [[CALayer alloc] init];
    self.indicatorCALayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.indicatorCALayer.frame = CGRectMake(0, 0, length, length);
    self.indicatorCALayer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/5);
    self.indicatorCALayer.cornerRadius = length/2;
    self.indicatorCALayer.shouldRasterize = YES;
    self.indicatorCALayer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.replicatorLayer.instanceCount = NUMBER_OF_LEADING_DOT;
    self.replicatorLayer.instanceDelay = 0.08;
    
    [self.replicatorLayer addSublayer:self.indicatorCALayer];
}

- (void)initializeCircle {
    self.indicatorCAShapeLayer = [[CAShapeLayer alloc] init];
    self.indicatorCAShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.indicatorCAShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.indicatorCAShapeLayer.lineWidth = self.frame.size.width/30;
    
    [self.replicatorLayer addSublayer:self.indicatorCAShapeLayer];
}

- (void)initializeArc {
    self.indicatorCAShapeLayer = [[CAShapeLayer alloc] init];
    self.indicatorCAShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.indicatorCAShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.indicatorCAShapeLayer.lineWidth = self.frame.size.width/24;
    
    CGFloat length = self.frame.size.width/5;
    self.indicatorCAShapeLayer.frame = CGRectMake(length, length, length*3, length*3);
    
    [self.replicatorLayer addSublayer:self.indicatorCAShapeLayer];
}

#pragma mark - appear animation
- (void)addAppearAnimation {
    switch (self.appearAnimationType) {
        case CCIndicatorAppearAnimationTypeSlideFromTop:
            [self addSlideFromTopAppearAnimation];
            break;
            
        case CCIndicatorAppearAnimationTypeSlideFromBottom:
            [self addSlideFromBottomAppearAnimation];
            break;
            
        case CCIndicatorAppearAnimationTypeSlideFromLeft:
            [self addSlideFromLeftAppearAnimation];
            break;
            
        case CCIndicatorAppearAnimationTypeSlideFromRight:
            [self addSlideFromRightAppearAnimation];
            break;
            
        case CCIndicatorAppearAnimationTypeFadeIn:
            [self addFadeInAppearAnimation];
            break;
    }
}

- (void)addFadeInAppearAnimation {
    CGFloat originalAlpha = self.alpha;
    self.alpha = 0.0;
    
    CGRect bounds = [UIScreen mainScreen].bounds;
    self.center = CGPointMake(bounds.size.width/2, bounds.size.height/2);
    
    [UIView animateWithDuration:0.35 animations:^{
        self.alpha = originalAlpha;
    } completion:^(BOOL finished) {
        [self addAnimation];
    }];
}

- (void)addSlideFromTopAppearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    self.center = CGPointMake(bounds.size.width/2, -length);
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(bounds.size.width/2, bounds.size.height/2);
    } completion:^(BOOL finished) {
        if (finished) {
            [self addAnimation];
        }
    }];
}

- (void)addSlideFromBottomAppearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    self.center = CGPointMake(bounds.size.width/2, bounds.size.height+length);
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(bounds.size.width/2, bounds.size.height/2);
    } completion:^(BOOL finished) {
        if (finished) {
            [self addAnimation];
        }
    }];
}

- (void)addSlideFromLeftAppearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    self.center = CGPointMake(-length, bounds.size.height/2);
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(bounds.size.width/2, bounds.size.height/2);
    } completion:^(BOOL finished) {
        if (finished) {
            [self addAnimation];
        }
    }];
}

- (void)addSlideFromRightAppearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    self.center = CGPointMake(bounds.size.width+length, bounds.size.height/2);
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(bounds.size.width/2, bounds.size.height/2);
    } completion:^(BOOL finished) {
        if (finished) {
            [self addAnimation];
        }
    }];
}

#pragma mark - activity animation
- (void)addAnimation {
    switch (self.currentTpye) {
        case CCIndicatorTypeScalingDots:
            [self.indicatorCALayer removeAllAnimations];
            [self addScaleAnimation];
            break;
            
        case CCIndicatorTypeLeadingDots:
            [self.indicatorCALayer removeAllAnimations];
            [self addLeadingAnimation];
            break;
            
        case CCIndicatorTypeCircle:
            [self.indicatorCAShapeLayer removeAllAnimations];
            [self addCircleAnimation];
            break;
            
        case CCIndicatorTypeArc:
            [self.indicatorCAShapeLayer removeAllAnimations];
            [self addArcAnimation];
            break;
    }
}

- (void)addScaleAnimation {
    CABasicAnimation *animation = [[CABasicAnimation alloc] init];
    animation.keyPath  = @"transform.scale";
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:0.1];
    animation.duration = DURATION_BASE*1.2;
    animation.repeatCount = INFINITY;
    
    [self.indicatorCALayer addAnimation:animation forKey:nil];
}

- (void)addLeadingAnimation {
    CGFloat radius = self.replicatorLayer.frame.size.width/2 - self.replicatorLayer.frame.size.width/5;
    CGFloat x = CGRectGetMidX(self.replicatorLayer.frame);
    CGFloat y = CGRectGetMidY(self.replicatorLayer.frame);
    CGFloat startAngle = -M_PI/2;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath addArcWithCenter:CGPointMake(x, y) radius:radius startAngle:startAngle endAngle:startAngle+M_PI*2 clockwise:YES];
    
    CAKeyframeAnimation *animation = [[CAKeyframeAnimation alloc] init];
    animation.keyPath = @"position";
    animation.path = bezierPath.CGPath;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.duration = DURATION_BASE;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = animation.duration+NUMBER_OF_LEADING_DOT*self.replicatorLayer.instanceDelay+0.06;
    animationGroup.repeatCount = INFINITY;
    animationGroup.animations = @[animation];
    
    [self.indicatorCALayer addAnimation:animationGroup forKey:nil];
}

- (void)addCircleAnimation {
    CGFloat radius = self.replicatorLayer.frame.size.width/2 - self.replicatorLayer.frame.size.width/5;
    CGFloat x = CGRectGetMidX(self.replicatorLayer.frame);
    CGFloat y = CGRectGetMidY(self.replicatorLayer.frame);
    
    UIBezierPath *circlePath = [UIBezierPath bezierPath];
    CGFloat startAngle = -M_PI/2;
    [circlePath addArcWithCenter:CGPointMake(x, y) radius:radius startAngle:startAngle endAngle:startAngle+2*M_PI clockwise:YES];
    self.indicatorCAShapeLayer.path = circlePath.CGPath;
    
    CABasicAnimation *appearAnimation = [[CABasicAnimation alloc] init];
    appearAnimation.keyPath = @"strokeEnd";
    appearAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    appearAnimation.toValue = [NSNumber numberWithFloat:1.0];
    appearAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    appearAnimation.duration = DURATION_BASE*1.8;
    
    CABasicAnimation *disappearAnimation = [[CABasicAnimation alloc] init];
    disappearAnimation.keyPath = @"strokeStart";
    disappearAnimation.beginTime = appearAnimation.duration;
    disappearAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    disappearAnimation.toValue = [NSNumber numberWithFloat:1.0];
    appearAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    disappearAnimation.duration = DURATION_BASE;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = appearAnimation.duration+disappearAnimation.duration;
    animationGroup.repeatCount = INFINITY;
    animationGroup.animations = @[appearAnimation, disappearAnimation];
    
    [self.indicatorCAShapeLayer addAnimation:animationGroup forKey:nil];
}

- (void)addArcAnimation {
    CGFloat radius = self.frame.size.width/2 - self.frame.size.width/5;
    CGFloat x = self.indicatorCAShapeLayer.frame.size.width/2;
    CGFloat y = self.indicatorCAShapeLayer.frame.size.height/2;
    
    UIBezierPath *arcPath = [UIBezierPath bezierPath];
    CGFloat startAngle = -M_PI/4;
    [arcPath addArcWithCenter:CGPointMake(x, y) radius:radius startAngle:startAngle endAngle:startAngle+M_PI/2 clockwise:YES];
    self.indicatorCAShapeLayer.path = arcPath.CGPath;
    
    CABasicAnimation *animation = [[CABasicAnimation alloc] init];
    animation.keyPath = @"transform.rotation.z";
    animation.fromValue = [NSNumber numberWithFloat:0.0];
    animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
    animation.duration = DURATION_BASE*1.5;
    animation.repeatCount = INFINITY;
    
    [self.indicatorCAShapeLayer addAnimation:animation forKey:nil];
}

#pragma mark - disappeat animation
- (void)addDisappearAnimation {
    switch (self.disappearAnimationType) {
        case CCIndicatorDisappearAnimationTypeSlideToTop:
            [self addSlideToTopDissappearAnimation];
            break;
            
        case CCIndicatorDisappearAnimationTypeSlideToBottom:
            [self addSlideToBottomDissappearAnimation];
            break;
            
        case CCIndicatorDisappearAnimationTypeSlideToLeft:
            [self addSlideToLeftDissappearAnimation];
            break;
            
        case CCIndicatorDisappearAnimationTypeSlideToRight:
            [self addSlideToRightDissappearAnimation];
            break;
            
        case CCIndicatorDisappearAnimationTypeFadeOut:
            [self addFadeOutDisappearAnimation];
            break;
    }
}

- (void)addFadeOutDisappearAnimation {
    CGFloat originalAlpha = self.alpha;
    
    [UIView animateWithDuration:0.35 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.alpha = originalAlpha;
        [self removeFromSuperview];
    }];
}

- (void)addSlideToTopDissappearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(bounds.size.width/2, -length);
    } completion:^(BOOL finished) {
         [self removeFromSuperview];
    }];
}
- (void)addSlideToBottomDissappearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(bounds.size.width/2, bounds.size.height+length);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)addSlideToLeftDissappearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(-length, bounds.size.height/2);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)addSlideToRightDissappearAnimation {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat length = self.frame.size.width;
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(bounds.size.width+length, bounds.size.height/2);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
