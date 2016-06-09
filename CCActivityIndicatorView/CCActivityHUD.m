#import "CCActivityHUD.h"
#import "UIImage+animatedGIF.h"
#import "Size.h"

#define DURATION_BASE 0.7

@interface CCActivityHUD ()

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) CAReplicatorLayer *replicatorLayer;
@property (strong, nonatomic) CALayer *indicatorCALayer;
@property (strong, nonatomic) CAShapeLayer *indicatorCAShapeLayer;
@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) UIColor *updatedColor;
@property CCActivityHUDIndicatorType currentTpye;
@property BOOL useGIF;

@end

@implementation CCActivityHUD

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

#pragma mark - public methods - show the view
- (void)showWithType:(CCActivityHUDIndicatorType)type {
    if (!self.superview) {
        [self initializeReplicatorLayer];
        [self initializeIndicatoeLayerWithType:type];
        self.currentTpye = type;
        self.useGIF = NO;
        
        // change the indicator color if user do not use the default color.
        // You will confused that why not change the indicator color within the relevant setter,
        // If so, I need to initialize self.indicatorCALayer or self.indicatorCAShapeLayer in the init method,
        // However, this will cause a problem (or bug) that the animation not works,
        // Meanwhile, when user use GIF instead of provided animation types,
        // the init method will create two useless instances,
        // since showing GIF not rely on self.indicatorCALayer or self.indicatorCAShapeLayer
        if (self.indicatorCALayer && self.updatedColor) {
            self.indicatorCALayer.backgroundColor = self.updatedColor.CGColor;
        } else if (self.indicatorCAShapeLayer && self.updatedColor) {
            self.indicatorCAShapeLayer.strokeColor = self.updatedColor.CGColor;
        }
        
        [self addBackgroundView];
        
        [[[UIApplication sharedApplication].windows lastObject] addSubview:self];
        [self.superview bringSubviewToFront:self];
        
        [self addAppearAnimation];
        
        if (self.isTheOnlyActiveView) {
            for (UIView *view in self.superview.subviews) {
                view.userInteractionEnabled = NO;
            }
        }
    }
}

- (void)show {
    [self showWithType:CCActivityHUDIndicatorTypeScalingDots];
}

- (void)showWithGIFName:(NSString *)GIFName {
    if (!self.superview) {
        CGFloat length = ViewFrameWidth/5;
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(length, length, length*3, length*3) ];
        self.imageView.layer.cornerRadius = self.self.cornerRadius;
        UIImage *gif = [UIImage animatedImageWithAnimatedGIFURL:[[NSBundle mainBundle] URLForResource:GIFName withExtension:nil]];
        self.imageView.image = gif;
        
        [self addSubview:self.imageView];
        
        self.useGIF = YES;
        
        [self addBackgroundView];
        
        [[[UIApplication sharedApplication].windows lastObject] addSubview:self];
        [self.superview bringSubviewToFront:self];
        
        [self addAppearAnimation];
        
        if (self.isTheOnlyActiveView) {
            for (UIView *view in self.superview.subviews) {
                view.userInteractionEnabled = NO;
            }
        }
    }
}

#pragma mark - public methods - dismiss the view
- (void)dismissWithText:(NSString *)text delay:(CGFloat)delay{
    if (self.superview) {
        if (text != nil || text.length != 0) {
            // remove animation or GIF
            if (self.replicatorLayer != nil) {
                [self.replicatorLayer removeFromSuperlayer];
            }
            if (self.imageView != nil) {
                [self.imageView removeFromSuperview];
            }
            
            [UIView animateWithDuration:0.3 animations:^{
                self.frame = CGRectMake(0, 0, BoundsWidthFor(Screen)/2.7, 63);
                self.center = BoundsCenterFor(Screen);
            }];
            
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ViewFrameWidth, ViewFrameHeight)];
            textLabel.numberOfLines = 0;
            textLabel.font = [UIFont systemFontOfSize:15];
            textLabel.textColor = [self inverseColorFor:self.backgroundColor];
            textLabel.textAlignment = NSTextAlignmentCenter;
            textLabel.text = text;
            [self addSubview:textLabel];
        }
        
        [self addDisappearAnimationWithDelay:delay];
        
        if (self.isTheOnlyActiveView) {
            for (UIView *view in self.superview.subviews) {
                view.userInteractionEnabled = YES;
            }
        }
    }
}

- (void)dismiss {
    [self dismissWithText:nil delay:0.0];
}

#pragma mark - life cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeFromSuperview {
    if (self.backgroundView != nil) {
        [self.backgroundView removeFromSuperview];
    }
    
    if (self.imageView != nil) {
        [self.imageView removeFromSuperview];
    }
    
    // change the scale to original if the disappear animation is zoom out
    self.transform = CGAffineTransformIdentity;
    
    CGFloat length = BoundsWidthFor(Screen)/6;
    self.frame = CGRectMake(-2*length, -2*length, length, length);
    
    [super removeFromSuperview];
}

#pragma mark - initialization
- (instancetype)init {
    self = [super init];
    
    if (self) {
        CGFloat length = BoundsWidthFor(Screen)/6;
        self.frame = CGRectMake(-2*length, -2*length, length, length);
        self.alpha = 0.7;
        self.backgroundColor = [UIColor blackColor];
        self.layer.cornerRadius = 10.0;
        
        self.isTheOnlyActiveView = YES;
    
        self.appearAnimationType = CCActivityHUDAppearAnimationTypeFadeIn;
        self.disappearAnimationType = CCActivityHUDDisappearAnimationTypeFadeOut;
        self.backgroundViewType = CCActivityHUDBackgroundViewTypeNone;
        
        [self addNotificationObserver];
    }
    
    return self;
}

- (void)addNotificationObserver {
    // The reason for invoking addAnimation when application enter foreground
    // is that if the application enter background when the activity indicator is animating,
    // the animation will not work when the application re-enter foreground.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAnimation) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)initializeReplicatorLayer {
    self.layer.sublayers = nil;
    
    self.replicatorLayer = [[CAReplicatorLayer alloc] init];
    self.replicatorLayer.frame = CGRectMake(0, 0, ViewFrameWidth, ViewFrameHeight);
    self.replicatorLayer.backgroundColor = [UIColor clearColor].CGColor;
    
    [self.layer addSublayer:self.replicatorLayer];
}

- (void)initializeIndicatoeLayerWithType:(CCActivityHUDIndicatorType)type {
    self.replicatorLayer.sublayers = nil;
    
    switch (type) {
        case CCActivityHUDIndicatorTypeScalingDots:
            [self initializeScalingDots];
            break;
            
        case CCActivityHUDIndicatorTypeLeadingDots:
            [self initializeLeadingDots];
            break;
            
        case CCActivityHUDIndicatorTypeCircle:
            [self initializeCircle];
            break;
            
        case CCActivityHUDIndicatorTypeArc:
            [self initializeArc];
            break;
    }
}

- (void)initializeScalingDots {
    CGFloat length = ViewFrameWidth*18/200;
    
    self.indicatorCALayer = [[CALayer alloc] init];
    self.indicatorCALayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.indicatorCALayer.frame = CGRectMake(0, 0, length, length);
    self.indicatorCALayer.position = CGPointMake(ViewFrameWidth/2, ViewFrameHeight/5);
    self.indicatorCALayer.cornerRadius = length/2;
    self.indicatorCALayer.transform = CATransform3DMakeScale(0.01, 0.01, 0.01);
    
    self.replicatorLayer.instanceCount = 15;
    self.replicatorLayer.instanceDelay = DURATION_BASE*1.2/self.replicatorLayer.instanceCount;
    CGFloat angle = 2*M_PI/self.replicatorLayer.instanceCount;
    self.replicatorLayer.instanceTransform = CATransform3DMakeRotation(angle, 0.0, 0.0, 0.1);
    
    [self.replicatorLayer addSublayer:self.indicatorCALayer];
}

- (void)initializeLeadingDots {
    CGFloat length = ViewFrameWidth*18/200;

    self.indicatorCALayer = [[CALayer alloc] init];
    self.indicatorCALayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.indicatorCALayer.frame = CGRectMake(0, 0, length, length);
    self.indicatorCALayer.position = CGPointMake(ViewFrameWidth/2, ViewFrameHeight/5);
    self.indicatorCALayer.cornerRadius = length/2;
    self.indicatorCALayer.shouldRasterize = YES;
    self.indicatorCALayer.rasterizationScale = Screen.scale;
    
    self.replicatorLayer.instanceCount = 3;
    self.replicatorLayer.instanceDelay = 0.08;
    
    [self.replicatorLayer addSublayer:self.indicatorCALayer];
}

- (void)initializeCircle {
    self.indicatorCAShapeLayer = [[CAShapeLayer alloc] init];
    self.indicatorCAShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.indicatorCAShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.indicatorCAShapeLayer.lineWidth = ViewFrameWidth/30;
    
    // Although animation for circle do not rely on self.replicatorLayer,
    // I still add it as a sublayer of self.replicatorLayer instead of self.layer,
    // for more convenient management of layers
    // when user show other types of indicator with the same CCActivityIndicatorView instance.
    [self.replicatorLayer addSublayer:self.indicatorCAShapeLayer];
}

- (void)initializeArc {
    self.indicatorCAShapeLayer = [[CAShapeLayer alloc] init];
    self.indicatorCAShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.indicatorCAShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.indicatorCAShapeLayer.lineWidth = ViewFrameWidth/24;
    
    CGFloat length = ViewFrameWidth/5;
    self.indicatorCAShapeLayer.frame = CGRectMake(length, length, length*3, length*3);
    
    // Although animation for arc do not rely on self.replicatorLayer,
    // I still add it as a sublayer of self.replicatorLayer instead of self.layer,
    // for more convenient management of layers
    // when user show other types of indicator with the same CCActivityIndicatorView instance.
    [self.replicatorLayer addSublayer:self.indicatorCAShapeLayer];
}

#pragma mark - background view
- (void)addBackgroundView {
    switch (self.backgroundViewType) {
        case CCActivityHUDBackgroundViewTypeNone:
            // do nothing
            break;
        
        case CCActivityHUDBackgroundViewTypeBlur:
            [self addBlurBackgroundView];
            break;
            
        case CCActivityHUDBackgroundViewTypeTransparent:
            [self addTransparentBackgroundView];
            break;
            
        case CCActivityHUDBackgroundViewTypeShadow:
            [self addShadowBackgroundView];
            break;
    }
}

- (void)addBlurBackgroundView {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffectView *backgroundView = [[UIVisualEffectView alloc] initWithFrame:BoundsFor(Screen)];
    backgroundView.effect = blurEffect;
    self.backgroundView = backgroundView;
                              
    [[[UIApplication sharedApplication].windows lastObject] addSubview:self.backgroundView];
}

- (void)addTransparentBackgroundView {
    self.backgroundView = [[UIView alloc] initWithFrame:BoundsFor(Screen)];
    self.backgroundView.backgroundColor = [UIColor blackColor];
    self.backgroundView.alpha = self.alpha-.2>0?self.alpha-.2:0.15;
    
    [[[UIApplication sharedApplication].windows lastObject] addSubview:self.backgroundView];
}

- (void)addShadowBackgroundView {
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    self.layer.shadowOpacity = 0.5;
}

#pragma mark - appear animation
- (void)addAppearAnimation {
    switch (self.appearAnimationType) {
        case CCActivityHUDAppearAnimationTypeSlideFromTop:
            [self addSlideFromTopAppearAnimation];
            break;
            
        case CCActivityHUDAppearAnimationTypeSlideFromBottom:
            [self addSlideFromBottomAppearAnimation];
            break;
            
        case CCActivityHUDAppearAnimationTypeSlideFromLeft:
            [self addSlideFromLeftAppearAnimation];
            break;
            
        case CCActivityHUDAppearAnimationTypeSlideFromRight:
            [self addSlideFromRightAppearAnimation];
            break;
            
        case CCActivityHUDAppearAnimationTypeZoomIn:
            [self addZoomInAppearAnimation];
            break;
            
        case CCActivityHUDAppearAnimationTypeFadeIn:
            [self addFadeInAppearAnimation];
            break;
    }
}

- (void)addFadeInAppearAnimation {
    CGFloat originalAlpha = self.alpha;
    self.alpha = 0.0;
    
    self.center = BoundsCenterFor(Screen);
    
    [UIView animateWithDuration:0.35 animations:^{
        self.alpha = originalAlpha;
    } completion:^(BOOL finished) {
        if (finished && !self.useGIF) {
            [self addAnimation];
        }
    }];
}

- (void)addSlideFromTopAppearAnimation {
    self.center = CGPointMake(BoundsCenterXFor(Screen), -ViewFrameWidth);
    
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.center = BoundsCenterFor(Screen);
    } completion:^(BOOL finished) {
        if (finished && !self.useGIF) {
            [self addAnimation];
        }
    }];
}

- (void)addSlideFromBottomAppearAnimation {
    self.center = CGPointMake(BoundsCenterXFor(Screen), BoundsHeightFor(Screen)+ViewFrameWidth);
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = BoundsCenterFor(Screen);
    } completion:^(BOOL finished) {
        if (finished && !self.useGIF) {
            [self addAnimation];
        }
    }];
}

- (void)addSlideFromLeftAppearAnimation {
    self.center = CGPointMake(-ViewFrameWidth, BoundsCenterYFor(Screen));
    
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = BoundsCenterFor(Screen);
    } completion:^(BOOL finished) {
        if (finished && !self.useGIF) {
            [self addAnimation];
        }
    }];
}

- (void)addSlideFromRightAppearAnimation {
    self.center = CGPointMake(BoundsWidthFor(Screen)+ViewFrameWidth, BoundsCenterYFor(Screen));
    
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = BoundsCenterFor(Screen);
    } completion:^(BOOL finished) {
        if (finished && !self.useGIF) {
            [self addAnimation];
        }
    }];
}

- (void)addZoomInAppearAnimation {
    self.center = BoundsCenterFor(Screen);
    
    self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
    [UIView animateWithDuration:0.15 animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.transform = CGAffineTransformIdentity;
                
                if (finished && !self.useGIF) {
                    [self addAnimation];
                }
            }];
        }];
    }];
}

#pragma mark - activity animation
- (void)addAnimation {
    switch (self.currentTpye) {
        case CCActivityHUDIndicatorTypeScalingDots:
            [self.indicatorCALayer removeAllAnimations];
            [self addScaleAnimation];
            break;
            
        case CCActivityHUDIndicatorTypeLeadingDots:
            [self.indicatorCALayer removeAllAnimations];
            [self addLeadingAnimation];
            break;
            
        case CCActivityHUDIndicatorTypeCircle:
            [self.indicatorCAShapeLayer removeAllAnimations];
            [self addCircleAnimation];
            break;
            
        case CCActivityHUDIndicatorTypeArc:
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
    CGFloat radius = FrameWidthFor(self.replicatorLayer)/2 - FrameWidthFor(self.replicatorLayer)/5;
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
    animationGroup.duration = animation.duration+self.replicatorLayer.instanceCount*self.replicatorLayer.instanceDelay+0.06;
    animationGroup.repeatCount = INFINITY;
    animationGroup.animations = @[animation];
    
    [self.indicatorCALayer addAnimation:animationGroup forKey:nil];
}

- (void)addCircleAnimation {
    CGFloat radius = FrameWidthFor(self.replicatorLayer)/2 - FrameWidthFor(self.replicatorLayer)/5;
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
    CGFloat radius = ViewFrameWidth/2 - ViewFrameWidth/5;
    CGFloat x = FrameWidthFor(self.indicatorCAShapeLayer)/2;
    CGFloat y = FrameHeightFor(self.indicatorCAShapeLayer)/2;
    
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
- (void)addDisappearAnimationWithDelay:(CGFloat)delay {
    switch (self.disappearAnimationType) {
        case CCActivityHUDDisappearAnimationTypeSlideToTop:
            [self addSlideToTopDissappearAnimationWithDelay:delay];
            break;
            
        case CCActivityHUDDisappearAnimationTypeSlideToBottom:
            [self addSlideToBottomDissappearAnimationWithDelay:delay];
            break;
            
        case CCActivityHUDDisappearAnimationTypeSlideToLeft:
            [self addSlideToLeftDissappearAnimationWithDelay:delay];
            break;
            
        case CCActivityHUDDisappearAnimationTypeSlideToRight:
            [self addSlideToRightDissappearAnimationWithDelay:delay];
            break;
            
        case CCActivityHUDDisappearAnimationTypeZoomOut:
            [self addZoomOutDisappearAnimationWithDelay:delay];
            break;
            
        case CCActivityHUDDisappearAnimationTypeFadeOut:
            [self addFadeOutDisappearAnimationWithDelay:delay];
            break;
    }
}

- (void)addFadeOutDisappearAnimationWithDelay:(CGFloat)delay {
    CGFloat originalAlpha = self.alpha;
    
    [UIView animateWithDuration:0.35 delay:delay options:kNilOptions  animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.alpha = originalAlpha;
        [self removeFromSuperview];
    }];
}

- (void)addSlideToTopDissappearAnimationWithDelay:(CGFloat)delay {
    [UIView animateWithDuration:0.25 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(BoundsCenterXFor(Screen), -ViewFrameWidth);
    } completion:^(BOOL finished) {
         [self removeFromSuperview];
    }];
}
- (void)addSlideToBottomDissappearAnimationWithDelay:(CGFloat)delay {
    [UIView animateWithDuration:0.25 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(BoundsCenterXFor(Screen), BoundsHeightFor(Screen)+ViewFrameWidth);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)addSlideToLeftDissappearAnimationWithDelay:(CGFloat)delay {
    [UIView animateWithDuration:0.15 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(-ViewFrameWidth, BoundsCenterYFor(Screen));
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)addSlideToRightDissappearAnimationWithDelay:(CGFloat)delay {
    [UIView animateWithDuration:0.15 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.center = CGPointMake(BoundsWidthFor(Screen)+ViewFrameWidth, BoundsCenterYFor(Screen));
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)addZoomOutDisappearAnimationWithDelay:(CGFloat)delay {
    [UIView animateWithDuration:0.15 delay:delay options:kNilOptions animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.01, 0.01);;
                
                [self removeFromSuperview];
            }];
        }];
    }];
}

#pragma helper methods
- (UIColor *)inverseColorFor:(UIColor *)color {
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

@end
