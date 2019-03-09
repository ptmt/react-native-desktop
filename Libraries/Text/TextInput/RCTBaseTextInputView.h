/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <AppKit/AppKit.h>

#import <React/RCTView.h>

#import "RCTBackedTextInputDelegate.h"
#import "RCTBackedTextInputViewProtocol.h"

@class RCTBridge;
@class RCTEventDispatcher;
@class RCTTextAttributes;
@class RCTTextSelection;

NS_ASSUME_NONNULL_BEGIN

@interface RCTBaseTextInputView : RCTView <RCTBackedTextInputDelegate>

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)decoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@property (nonatomic, readonly) NSView<RCTBackedTextInputViewProtocol> *backedTextInputView;

@property (nonatomic, strong, nullable) RCTTextAttributes *textAttributes;
@property (nonatomic, assign) NSEdgeInsets reactPaddingInsets;
@property (nonatomic, assign) NSEdgeInsets reactBorderInsets;

@property (nonatomic, copy, nullable) RCTDirectEventBlock onContentSizeChange;
@property (nonatomic, copy, nullable) RCTDirectEventBlock onSelectionChange;
@property (nonatomic, copy, nullable) RCTDirectEventBlock onChange;
@property (nonatomic, copy, nullable) RCTDirectEventBlock onTextInput;
//@property (nonatomic, copy, nullable) RCTDirectEventBlock onScroll;

@property (nonatomic, assign) NSInteger mostRecentEventCount;
@property (nonatomic, assign) BOOL blurOnSubmit;
@property (nonatomic, assign) BOOL selectTextOnFocus;
@property (nonatomic, assign) BOOL clearTextOnFocus;
@property (nonatomic, copy) RCTTextSelection *selection;
@property (nonatomic, strong, nullable) NSNumber *maxLength;
@property (nonatomic, copy) NSAttributedString *attributedText;
@property (nonatomic, copy, nullable) NSString *placeholder;
@property (nonatomic, strong, nullable) NSColor *placeholderColor;

@end

NS_ASSUME_NONNULL_END
