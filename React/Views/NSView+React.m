/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSView+React.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import <objc/runtime.h>

#import "RCTAssert.h"
#import "RCTLog.h"
#import "RCTShadowView.h"
#import "RCTTouchHandler.h"

@implementation NSView (React)

- (NSNumber *)reactTag
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactTag:(NSNumber *)reactTag
{
  objc_setAssociatedObject(self, @selector(reactTag), reactTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 * Enables this view for the key-view loop
 */
- (NSNumber *)tabIndex
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setTabIndex:(NSNumber *)tabIndex
{
  objc_setAssociatedObject(self, @selector(tabIndex), tabIndex, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#if RCT_DEV

- (RCTShadowView *)_DEBUG_reactShadowView
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)_DEBUG_setReactShadowView:(RCTShadowView *)shadowView
{
  // Use assign to avoid keeping the shadowView alive it if no longer exists
  objc_setAssociatedObject(self, @selector(_DEBUG_reactShadowView), shadowView, OBJC_ASSOCIATION_ASSIGN);
}

#endif

- (BOOL)isReactRootView
{
  return RCTIsReactRootView(self.reactTag);
}

- (NSNumber *)reactTagAtPoint:(CGPoint)point
{
  NSView *view = [self hitTest:point];
  while (view && !view.reactTag) {
    view = view.superview;
  }
  return view.reactTag;
}

- (void)insertReactSubview:(NSView *)subview atIndex:(__unused NSInteger)atIndex
{
  // TODO: Do we really need ability to add subviews at any index?
  NSMutableArray * array = [[NSMutableArray alloc] initWithArray:self.subviews];
  [array insertObject:subview atIndex:atIndex];
  self.subviews = array;
}

- (void)removeReactSubview:(NSView *)subview
{
  RCTAssert(subview.superview == self, @"%@ is a not a subview of %@", subview, self);
  [subview removeFromSuperview];
}

- (NSArray<NSView *> *)reactSubviews
{
  return self.subviews;
}

- (NSView *)reactSuperview
{
  return self.superview;
}

- (void)reactSetFrame:(CGRect)frame
{
  // These frames are in terms of anchorPoint = topLeft, but internally the
  // views are anchorPoint = center for easier scale and rotation animations.
  // Convert the frame so it works with anchorPoint = center.
  CGPoint position = {CGRectGetMidX(frame), CGRectGetMidY(frame)};
  CGRect bounds = {CGPointZero, frame.size};

  // Avoid crashes due to nan coords
  if (isnan(position.x) || isnan(position.y) ||
      isnan(bounds.origin.x) || isnan(bounds.origin.y) ||
      isnan(bounds.size.width) || isnan(bounds.size.height)) {
    RCTLogError(@"Invalid layout for (%@)%@", self.reactTag, self);
    return;
  }

  self.frame = frame;
  // TODO: why position matters? It's only produce bugs
  //self.layer.position = position;
  self.layer.bounds = bounds;
}

- (void)reactSetInheritedBackgroundColor:(NSColor *)inheritedBackgroundColor
{
  if (![self wantsLayer]) {
    CALayer *viewLayer = [CALayer layer];
    [self setWantsLayer:YES];
    [self setLayer:viewLayer];
  }
  [self.layer setBackgroundColor:[inheritedBackgroundColor CGColor]];

}

- (NSViewController *)reactViewController
{
  id responder = [self nextResponder];
  while (responder) {
    if ([responder isKindOfClass:[NSViewController class]]) {
      return responder;
    }
    responder = [responder nextResponder];
  }
  return nil;
}

- (void)reactAddControllerToClosestParent:(NSViewController *)controller
{
  if (!controller.parentViewController) {
    NSView *parentView = (NSView *)self.reactSuperview;
    while (parentView) {
      if (parentView.reactViewController) {
        [parentView.reactViewController addChildViewController:controller];
        //[controller didMoveToParentViewController:parentView.reactViewController];
        break;
      }
      parentView = (NSView *)parentView.reactSuperview;
    }
    return;
  }
}

- (NSView *)findNextKeyView:(NSView *)view visisted:(NSMutableSet *)visited
{
  if ([view canBecomeKeyView]) {
    return view;
  }
  [visited addObject:view];

  if ([view subviews] && [view subviews].count > 0) {
    int length = (int) [view subviews].count;
    for (int i=0; i < length; i++) {
      //NSLog(@"%i %hhd", i, view.subviews[i].canBecomeKeyView);
      if (![visited containsObject:view.subviews[i]] && view.subviews[i].canBecomeKeyView) {
        return view.subviews[i];
      }
      if (![visited containsObject:view.subviews[i]] && view.subviews[i].subviews.count > 0) {
        NSView *found = [self findNextKeyView:view.subviews[i] visisted:visited];
        if (found) {
          return found;
        }
      }
    }
  }

  if ([view superview] && ![visited containsObject:[view superview]]) {
    return [self findNextKeyView:[view superview] visisted:visited];
  } else {
    return nil;
  }
  
}

- (BOOL)becomeFirstResponder
{
  BOOL result = [super becomeFirstResponder];
  if (result && ([self canBecomeKeyView])) {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTFirstResponderDidChangeNotification
                                                        object:nil
                                                      userInfo:@{@"reactTag": (self.reactTag)}];

    NSMutableSet *visitedViews = [NSMutableSet new];
    [visitedViews addObject:self];
    //self.nextKeyView = [self findNextKeyView:self visisted:visitedViews];
  }
  return result;
}

- (BOOL)resignFirstResponder
{
  BOOL result = [super resignFirstResponder];
  if (result)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTFirstResponderDidChangeNotification
                                                        object:nil
                                                      userInfo:@{@"reactTag": @(1)}];
  }
  return result;
}

- (void)keyDown:(NSEvent *)theEvent
{
  if (theEvent.keyCode == 48 && [[[self window] firstResponder] isEqualTo:self]) {
    [[self window] recalculateKeyViewLoop];
    [[self window] selectNextKeyView:self];
  }
  [super keyDown:theEvent];
}


- (BOOL)canBecomeKeyView
{
  return [[self tabIndex] isNotEqualTo:nil];
}

- (BOOL)canBecomeFirstResponder
{
  return [[self tabIndex] isNotEqualTo:nil];
}

- (BOOL)acceptsFirstResponder
{
  return [[self tabIndex] isNotEqualTo:nil];
}

/**
 * Responder overrides - to be deprecated.
 */
- (void)reactWillMakeFirstResponder {};
- (void)reactDidMakeFirstResponder {};
- (BOOL)reactRespondsToTouch:(__unused NSEvent *)touch
{
  return YES;
}

@end
