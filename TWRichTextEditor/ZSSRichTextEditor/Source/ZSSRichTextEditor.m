//
//  ZSSRichTextEditorViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ZSSRichTextEditor.h"
#import "ZSSBarButtonItem.h"
#import "HRColorUtil.h"
#import "ZSSTextView.h"
#import "RYIndicatorBackgroudView.h"

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#define TOOL_BAR_HEIGHT    49
#define CORNER_RADIUS_7     7

#define SCREEN_SIZE         [UIScreen mainScreen].bounds.size


@import JavaScriptCore;


/**
 
 UIWebView modifications for hiding the inputAccessoryView
 
 **/
@interface UIWebView (HackishAccessoryHiding)
@property (nonatomic, assign) BOOL hidesInputAccessoryView;
@end

@implementation UIWebView (HackishAccessoryHiding)

static const char * const hackishFixClassName = "UIWebBrowserViewMinusAccessoryView";
static Class hackishFixClass = Nil;

- (UIView *)hackishlyFoundBrowserView {
    UIScrollView *scrollView = self.scrollView;
    
    UIView *browserView = nil;
    for (UIView *subview in scrollView.subviews) {
        if ([NSStringFromClass([subview class]) hasPrefix:@"UIWebBrowserView"]) {
            browserView = subview;
            break;
        }
    }
    return browserView;
}

- (id)methodReturningNil {
    return nil;
}

- (void)ensureHackishSubclassExistsOfBrowserViewClass:(Class)browserViewClass {
    if (!hackishFixClass) {
        Class newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        IMP nilImp = [self methodForSelector:@selector(methodReturningNil)];
        class_addMethod(newClass, @selector(inputAccessoryView), nilImp, "@@:");
        objc_registerClassPair(newClass);
        
        hackishFixClass = newClass;
    }
}

- (BOOL) hidesInputAccessoryView {
    UIView *browserView = [self hackishlyFoundBrowserView];
    return [browserView class] == hackishFixClass;
}

- (void) setHidesInputAccessoryView:(BOOL)value {
    UIView *browserView = [self hackishlyFoundBrowserView];
    if (browserView == nil) {
        return;
    }
    [self ensureHackishSubclassExistsOfBrowserViewClass:[browserView class]];
    
    if (value) {
        object_setClass(browserView, hackishFixClass);
    }
    else {
        Class normalClass = objc_getClass("UIWebBrowserView");
        object_setClass(browserView, normalClass);
    }
    [browserView reloadInputViews];
}

@end


@interface ZSSRichTextEditor ()
{

    float _keyboardOringalY;
    
}

/*
 *  Scroll view containing the toolbar
 */
@property (nonatomic, strong) UIScrollView *toolBarScroll;

/*
 *  Toolbar containing ZSSBarButtonItems
 */
@property (nonatomic, strong) UIToolbar *toolbar;

/*
 *  Holder for all of the toolbar components
 */
@property (nonatomic, strong) UIView *toolbarHolder;

/*
 *  String for the HTML
 */
@property (nonatomic, strong) NSString *htmlString;

/*
 *  UIWebView for writing/editing/displaying the content
 */
@property (nonatomic, strong) UIWebView *editorView;

/*
 *  ZSSTextView for displaying the source code for what is displayed in the editor view
 */
@property (nonatomic, strong) ZSSTextView *sourceView;

/*
 *  CGRect for holding the frame for the editor view
 */
@property (nonatomic) CGRect editorViewFrame;

/*
 *  BOOL for holding if the resources are loaded or not
 */
@property (nonatomic) BOOL resourcesLoaded;

/*
 *  Array holding the enabled editor items
 */
@property (nonatomic, strong) NSArray *editorItemsEnabled;

/*
 *  Alert View used when inserting links/images
 */
@property (nonatomic, strong) UIAlertView *alertView;

/*
 *  NSString holding the selected links URL value
 */
@property (nonatomic, strong) NSString *selectedLinkURL;

/*
 *  NSString holding the selected links title value
 */
@property (nonatomic, strong) NSString *selectedLinkTitle;

/*
 *  NSString holding the selected image URL value
 */
@property (nonatomic, strong) NSString *selectedImageURL;

/*
 *  NSString holding the selected image Alt value
 */
@property (nonatomic, strong) NSString *selectedImageAlt;

/*
 *  CGFloat holdign the selected image scale value
 */
@property (nonatomic, assign) CGFloat selectedImageScale;

/*
 *  NSString holding the base64 value of the current image
 */
@property (nonatomic, strong) NSString *imageBase64String;

/*
 *  Bar button item for the keyboard dismiss button in the toolbar
 */
@property (nonatomic, strong) UIBarButtonItem *keyboardItem;

/*
 *  Array for custom bar button items
 */
@property (nonatomic, strong) NSMutableArray *customBarButtonItems;

/*
 *  Array for custom ZSSBarButtonItems
 */
@property (nonatomic, strong) NSMutableArray *customZSSBarButtonItems;

/*
 *  NSString holding the html
 */
@property (nonatomic, strong) NSString *internalHTML;

/*
 *  NSString holding the css
 */
@property (nonatomic, strong) NSString *customCSS;

/*
 *  BOOL for if the editor is loaded or not
 */
@property (nonatomic) BOOL editorLoaded;

/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIImagePickerController *imagePicker;


@property (nonatomic, strong) UIView *toolbarView;

/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIView *voiceView;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) RYIndicatorBackgroudView *selectView;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) RYIndicatorBackgroudView *textStyleView;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIButton *textStyleButton;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) RYIndicatorBackgroudView *textSizeView;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIButton *textSizeButton;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) RYIndicatorBackgroudView *textAlignmentView;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIButton *textAlignmentButton;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) RYIndicatorBackgroudView *textColorView;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIButton *textColorButton;

/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) NSArray *textColorArray;

/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, copy) NSString *pasteBoardText;


/*
 *  Method for getting a version of the html without quotes
 */
- (NSString *)removeQuotesFromHTML:(NSString *)html;

/*
 *  Method for getting a tidied version of the html
 */
- (NSString *)tidyHTML:(NSString *)html;

/*
 * Method for enablign toolbar items
 */
- (void)enableToolbarItems:(BOOL)enable;

/*
 *  Setter for isIpad BOOL
 */
- (BOOL)isIpad;

@end

@implementation ZSSRichTextEditor (private)

- (void)_removeLast{

    if ([self.selectView superview]) {
        
        [self.selectView removeFromSuperview];
    }
    if ([self.textStyleView superview]) {
        
        [self.textStyleView removeFromSuperview];
    }
    if ([self.textSizeView superview]) {
        
        [self.textSizeView removeFromSuperview];
    }
    if ([self.textAlignmentView superview]) {
        
        [self.textAlignmentView removeFromSuperview];
    }
    if ([self.textColorView superview]) {
        
        [self.textColorView removeFromSuperview];
    }
}

- (void)keyboardWasShown:(NSNotification*)aNotification{
    //键盘高度
    CGRect keyBoardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    _keyboardOringalY = keyBoardFrame.origin.y;
    
}
- (void)keyboardWillBeHidden:(NSNotification*)aNotification{
    
    CGRect keyBoardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    _keyboardOringalY = keyBoardFrame.origin.y;
}
- (void)keyboardDidChangeFrame:(NSNotification*)aNotification{
    
    CGRect keyBoardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    _keyboardOringalY = keyBoardFrame.origin.y;
}

- (void)_voice{
    
    [self _removeLast];
    
    if (!self.voiceView) {
        
        self.voiceView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, TOOL_BAR_HEIGHT)];
        
        float doneButtonWidth = 59;
        UIButton *done = [UIButton buttonWithType:UIButtonTypeCustom];
        [done setTitle:@"完成" forState:UIControlStateNormal];
        done.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - doneButtonWidth) / 2.0, (TOOL_BAR_HEIGHT - 32) / 2.0 - 2, doneButtonWidth, 32);
        [done addTarget:self action:@selector(_done) forControlEvents:UIControlEventTouchUpInside];
        [done setTitleColor:[UIColor colorWithRed:74 / 255.0 green:189 / 255.0 blue:204 / 255.0 alpha:1] forState:UIControlStateNormal];
        done.titleLabel.font = [UIFont systemFontOfSize:16];
        done.clipsToBounds = YES;
        done.layer.cornerRadius = 7.0f;
        done.layer.borderWidth = 1.0f;
        done.layer.borderColor = [[UIColor colorWithRed:74 / 255.0 green:189 / 255.0 blue:204 / 255.0 alpha:1] CGColor];
        
        [self.voiceView addSubview:done];
        
        
        float width = (SCREEN_SIZE.width - doneButtonWidth) / 2.0 - 6 - 30;
        float height = 3;
        
        NSInteger count = ceilf(width / (3.0 + 6.0));
        
        float elementWidth = 3;
        
        for (int i = 0; i < count; i ++) {
            
            float leftOrigalX = (SCREEN_SIZE.width - doneButtonWidth) / 2.0 - 12 - 9 * i;
            float origalY = (TOOL_BAR_HEIGHT - height - 6) / 2.0;
            
            UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(leftOrigalX, origalY, elementWidth, height)];
            leftView.backgroundColor = [UIColor colorWithRed:74 / 255.0 green:189 / 255.0 blue:204 / 255.0 alpha:1];
            leftView.tag = i + 100;
            leftView.clipsToBounds = YES;
            leftView.layer.cornerRadius = 1.5f;
            [self.voiceView addSubview:leftView];
            
            float rightOrigalX = (SCREEN_SIZE.width + doneButtonWidth) / 2.0 + 12 + 9 * i;
            
            UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(rightOrigalX, origalY, elementWidth, height)];
            rightView.backgroundColor = [UIColor colorWithRed:74 / 255.0 green:189 / 255.0 blue:204 / 255.0 alpha:1];
            rightView.tag = i + 100;
            rightView.clipsToBounds = YES;
            rightView.layer.cornerRadius = 1.5f;
            [self.voiceView addSubview:rightView];
        }
        NSLog(@"%ld", count);
        
    }
    
    
    self.voiceView.backgroundColor = [UIColor whiteColor];
    [self.toolBarScroll addSubview:self.voiceView];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
      
        __block NSInteger index = 0;
        
        NSInteger height = arc4random() % 30;
        [NSTimer scheduledTimerWithTimeInterval:0.03 repeats:YES block:^(NSTimer * _Nonnull timer) {
            
            float origalY = (TOOL_BAR_HEIGHT - height - 6) / 2.0;
            
            float doneButtonWidth = 59;

            float width = (SCREEN_SIZE.width - doneButtonWidth) / 2.0 - 6 - 30;

            NSInteger count = ceilf(width / (3.0 + 6.0));

            NSArray *subviews = self.voiceView.subviews;
            for (int i = 0; i < count; i ++ ) {
                
                for (UIView *view in subviews) {
                    if (view.tag == (100 + index)) {
                        
                        [UIView animateWithDuration:0.1 animations:^{
                            
                            view.frame = CGRectMake(view.frame.origin.x, origalY, view.frame.size.width, height);
                            
                        }];
                    }
                }
            }
            index = index + 1;
            
            if (index >= count) {
                
                [timer invalidate];
            }
        }];
    }];
    
   
    
  
}
- (void)_done{

    [self.voiceView removeFromSuperview];
}


- (void)_select{
    
    if ([self.textAlignmentView superview]) {
        
        [self.textAlignmentView removeFromSuperview];
    }
    if ([self.textSizeView superview]) {
        
        [self.textSizeView removeFromSuperview];
    }
    if ([self.textColorView superview]) {
        
        [self.textColorView removeFromSuperview];
    }
    if ([self.textStyleView superview]) {
        
        [self.textStyleView removeFromSuperview];
    }
    if ([self.selectView superview]) {
        
        [self.selectView removeFromSuperview];
    }
    else{
    
        float width = 42;
        float height = 36;
        float oringalX = SCREEN_SIZE.width / 6.0 * 1 + SCREEN_SIZE.width / 6.0 / 2.0 - (width / 2.0);
        float oringalY = _keyboardOringalY - 64 - height - TOOL_BAR_HEIGHT;
        
        if (!self.selectView) {
            
            self.selectView = [[RYIndicatorBackgroudView alloc] initWithFrame:CGRectMake(oringalX, oringalY, width, height)];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(0, 0, width, 28);
            [button setTitle:@"全选" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:16];
            [button addTarget:self action:@selector(_selectAll) forControlEvents:UIControlEventTouchUpInside];
            
            [self.selectView addSubview:button];
        }
        self.selectView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.selectView];
    }
}
- (void)_selectAll{
    
    [self.selectView removeFromSuperview];
    NSString *trigger = @"zss_editor.selectAll();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)_textStyle{
    
    if ([self.selectView superview]) {
        
        [self.selectView removeFromSuperview];
    }
    if ([self.textAlignmentView superview]) {
        
        [self.textAlignmentView removeFromSuperview];
    }
    if ([self.textSizeView superview]) {
        
        [self.textSizeView removeFromSuperview];
    }
    if ([self.textColorView superview]) {
        
        [self.textColorView removeFromSuperview];
    }
    if ([self.textStyleView superview]) {
        
        [self.textStyleView removeFromSuperview];
    }
    else{
    
        float width = 42 * 3;
        float height = 36;
        float oringalX = SCREEN_SIZE.width / 6.0 * 2 + SCREEN_SIZE.width / 6.0 / 2.0 - (width / 2.0);
        float oringalY = _keyboardOringalY - 64 - height - TOOL_BAR_HEIGHT;
        if (!self.textStyleView) {
            
            self.textStyleView = [[RYIndicatorBackgroudView alloc] initWithFrame:CGRectMake(oringalX, oringalY, width, height)];
            
            NSArray *images = [NSArray arrayWithObjects:@"t31", @"t32", @"t33", nil];
            
            float buttonWidth = width / images.count;
            float buttonHeight = 28;
            
            for (int i = 0; i < images.count; i ++) {
                
                NSString *imagestr = [images objectAtIndex:i];
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(buttonWidth * i, 0, buttonWidth, buttonHeight);
                button.tag = i + 100;
                [button setImage:[UIImage imageNamed:imagestr] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(_style:) forControlEvents:UIControlEventTouchUpInside];
                [self.textStyleView addSubview:button];
            }
        }
        self.textStyleView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.textStyleView];
    }
}
- (void)_style:(UIButton *)sender{

    switch (sender.tag) {
        case 100:
        {
            NSString *trigger = @"zss_editor.setBold();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
        }
            break;
        case 101:
        {
            NSString *trigger = @"zss_editor.clearStyle();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];

        }
            break;
        case 102:
        {
            NSString *trigger = @"zss_editor.setItalic();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
        }
            break;
            
        default:
            break;
    }
}

- (void)_textSize{
    
    if ([self.selectView superview]) {
        
        [self.selectView removeFromSuperview];
    }
    if ([self.textStyleView superview]) {
        
        [self.textStyleView removeFromSuperview];
    }
    if ([self.textColorView superview]) {
        
        [self.textColorView removeFromSuperview];
    }
    if ([self.textAlignmentView superview]) {
        
        [self.textAlignmentView removeFromSuperview];
    }
    if ([self.textSizeView superview]) {
        
        [self.textSizeView removeFromSuperview];
    }
    else{
    
        float width = 42 * 2;
        float height = 36;
        float oringalX = SCREEN_SIZE.width / 6.0 * 3 + SCREEN_SIZE.width / 6.0 / 2.0 - (width / 2.0);
        float oringalY = _keyboardOringalY - 64 - height - TOOL_BAR_HEIGHT;
        if (!self.textSizeView) {
            
            self.textSizeView = [[RYIndicatorBackgroudView alloc] initWithFrame:CGRectMake(oringalX, oringalY, width, height)];
            
            NSArray *images = [NSArray arrayWithObjects:@"t41", @"t42", nil];
            
            float buttonWidth = width / images.count;
            float buttonHeight = 28;
            
            for (int i = 0; i < images.count; i ++) {
                
                NSString *imagestr = [images objectAtIndex:i];
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(buttonWidth * i, 0, buttonWidth, buttonHeight);
                button.tag = i + 100;
                [button setImage:[UIImage imageNamed:imagestr] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(_textSize:) forControlEvents:UIControlEventTouchUpInside];
                [self.textSizeView addSubview:button];
            }
        }
        self.textSizeView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.textSizeView];
    }
}
- (void)_textSize:(UIButton *)sender{
    
    switch (sender.tag) {
        case 100:
        {
            NSString *trigger = @"zss_editor.turnBig();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
        }
            break;
        case 101:
        {
            NSString *trigger = @"zss_editor.turnSmall();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
        }
            break;
            
        default:
            break;
    }
}

- (void)_textAlignment{
 
    if ([self.selectView superview]) {
        
        [self.selectView removeFromSuperview];
    }
    if ([self.textStyleView superview]) {
        
        [self.textStyleView removeFromSuperview];
    }
    if ([self.textColorView superview]) {
        
        [self.textColorView removeFromSuperview];
    }
    if ([self.textSizeView superview]) {
        
        [self.textSizeView removeFromSuperview];
    }
    if ([self.textAlignmentView superview]) {
        
        [self.textAlignmentView removeFromSuperview];
    }
    else{
    
        float width = 42 * 3;
        float height = 36;
        float oringalX = SCREEN_SIZE.width / 6.0 * 4 + SCREEN_SIZE.width / 6.0 / 2.0 - (width / 2.0);
        float oringalY = _keyboardOringalY - 64 - height - TOOL_BAR_HEIGHT;
        if (!self.textAlignmentView) {
            
            self.textAlignmentView = [[RYIndicatorBackgroudView alloc] initWithFrame:CGRectMake(oringalX, oringalY, width, height)];
            NSArray *images = [NSArray arrayWithObjects:@"t51", @"t52", @"t53", nil];
            
            float buttonWidth = width / images.count;
            float buttonHeight = 28;
            
            for (int i = 0; i < images.count; i ++) {
                
                NSString *imagestr = [images objectAtIndex:i];
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(buttonWidth * i, 0, buttonWidth, buttonHeight);
                button.tag = i + 100;
                [button setImage:[UIImage imageNamed:imagestr] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(_alignment:) forControlEvents:UIControlEventTouchUpInside];
                [self.textAlignmentView addSubview:button];
            }
        }
        self.textAlignmentView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.textAlignmentView];
    }
}
- (void)_alignment:(UIButton *)sender{

    switch (sender.tag) {
        case 100:
        {
            NSString *trigger = @"zss_editor.setJustifyLeft();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
        }
            break;
        case 101:
        {
            NSString *trigger = @"zss_editor.setJustifyCenter();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
        }
            break;
        case 102:
        {
            NSString *trigger = @"zss_editor.setJustifyRight();";
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
        }
            break;
            
        default:
            break;
    }

}

- (void)_textColor{
    
    if ([self.selectView superview]) {
        
        [self.selectView removeFromSuperview];
    }
    if ([self.textStyleView superview]) {
        
        [self.textStyleView removeFromSuperview];
    }
    if ([self.textSizeView superview]) {
        
        [self.textSizeView removeFromSuperview];
    }
    if ([self.textAlignmentView superview]) {
        
        [self.textAlignmentView removeFromSuperview];
    }
    if ([self.textColorView superview]) {
        
        [self.textColorView removeFromSuperview];
    }
    else{
    
        float width = 42 * 7;
        float height = 30 * 2 + 9;
        float oringalX = SCREEN_SIZE.width - width;
        float oringalY = _keyboardOringalY - 64 - height - TOOL_BAR_HEIGHT;
        
        [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
        if (!self.textColorView) {
            
            self.textColorView = [[RYIndicatorBackgroudView alloc] initWithFrame:CGRectMake(oringalX, oringalY, width, height) withRightDistance:SCREEN_SIZE.width / 6.0 / 3];
            
            NSArray *images = [NSArray arrayWithArray:self.textColorArray];
            
            float buttonWidth = width / 7.0;
            float buttonHeight = 30;
            
            for (int i = 0; i < images.count; i ++) {
                
                
                NSString *imagestr = [images objectAtIndex:i];

                CGRect rect = CGRectZero;
                if (i < 7) {
                    
                    rect = CGRectMake(buttonWidth * i, 0, buttonWidth, buttonHeight);
                }
                else{
                    
                    rect = CGRectMake(buttonWidth * (i - 7), 30, buttonWidth, buttonHeight);
                }
                
                UIView *view = [[UIView alloc] initWithFrame:rect];
                UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake((view.frame.size.width - 22) / 2.0, (view.frame.size.height - 22) / 2.0, 22, 22)];
                
                long colorLong = strtoul([imagestr cStringUsingEncoding:NSUTF8StringEncoding], 0, 16);

                colorView.backgroundColor = UIColorFromRGB(colorLong);
                colorView.clipsToBounds = YES;
                colorView.layer.cornerRadius = 6.0f;
                
                [view addSubview:colorView];
                
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = view.bounds;
                button.tag = i + 100;
                [button setImage:[UIImage imageNamed:imagestr] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(_color:) forControlEvents:UIControlEventTouchUpInside];
                [view  addSubview:button];
                
                [self.textColorView addSubview:view];
            }
            
        }
        self.textColorView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.textColorView];
    }
}
- (void)_color:(UIButton *)sender{
    
    [self.textColorView removeFromSuperview];
    
    NSArray *images = [NSArray arrayWithArray:self.textColorArray];
    
    if (sender.tag >= 100 && sender.tag - 100 < images.count) {
        
        NSString *imagestr = [images objectAtIndex:sender.tag - 100];
        long colorLong = strtoul([imagestr cStringUsingEncoding:NSUTF8StringEncoding], 0, 16);
        
        UIColor *color = UIColorFromRGB(colorLong);
        NSString *hex = [NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)];
        
        NSString *trigger = [NSString stringWithFormat:@"zss_editor.setTextColor(\"%@\");", hex];
        
            [self.editorView stringByEvaluatingJavaScriptFromString:trigger];            
    }
}

@end

/*
 
 ZSSRichTextEditor
 
 */
@implementation ZSSRichTextEditor

//Scale image from device
static CGFloat kJPEGCompression = 0.8;
static CGFloat kDefaultScale = 0.5;

#pragma mark - View Did Load Section
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //Initialise variables
    self.editorLoaded = NO;
    self.receiveEditorDidChangeEvents = NO;
    self.alwaysShowToolbar = NO;
    self.shouldShowKeyboard = YES;
    self.formatHTML = YES;
    
    //Initalise enabled toolbar items array
    self.enabledToolbarItems = [[NSArray alloc] init];
    
    //Frame for the source view and editor view
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    //Source View
    [self createSourceViewWithFrame:frame];
    
    //Editor View
    [self createEditorViewWithFrame:frame];
    
    
    //Scrolling View
    [self createToolBarScroll];
    
    //Toolbar with icons
    [self createToolbarView];
    
    //Parent holding view
    [self createParentHoldingView];
    
    self.textColorArray = [NSArray arrayWithObjects:
                           @"0xE70012",
                           @"0xF39900",
                           @"0xF7EF14",
                           @"0x22AD38",
                           @"0x03A1E9",
                           @"0x181C62",
                           @"0x930883",
                           @"0x956034",
                           @"0x6A3806",
                           @"0x000000",
                           @"0x595858",
                           @"0x898989",
                           @"0xCACACB",
                           @"0xF0F0F0", nil];
    
    [self.view addSubview:self.toolbarHolder];
    
    //Build the toolbar
    [self buildToolbar];
    
    //Load Resources
    if (!self.resourcesLoaded) {
        
        [self loadResources];
        
    }
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_resetPasteBoard) name:@"resetPasteBoard" object:nil];
}

#pragma mark - View Will Appear Section
- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    //Add observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - View Will Disappear Section
- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    //Remove observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}

#pragma mark - Set Up View Section

- (void)createSourceViewWithFrame:(CGRect)frame {
    
    self.sourceView = [[ZSSTextView alloc] initWithFrame:frame];
    self.sourceView.hidden = YES;
    self.sourceView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.sourceView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.sourceView.font = [UIFont fontWithName:@"Courier" size:13.0];
    self.sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.sourceView.autoresizesSubviews = YES;
    self.sourceView.delegate = self;
    [self.view addSubview:self.sourceView];
    
}

- (void)createEditorViewWithFrame:(CGRect)frame {
    
    self.editorView = [[UIWebView alloc] initWithFrame:frame];
    self.editorView.delegate = self;
    self.editorView.hidesInputAccessoryView = YES;
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    self.editorView.scalesPageToFit = YES;
    self.editorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.editorView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.editorView.scrollView.bounces = NO;
    self.editorView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.editorView];
    
}

- (void)setUpImagePicker {
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.allowsEditing = YES;
    self.selectedImageScale = kDefaultScale; //by default scale to half the size
    
}

- (void)createToolBarScroll {
    
//    self.toolBarScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self isIpad] ? self.view.frame.size.width : self.view.frame.size.width - 44, 44)];
    self.toolBarScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self isIpad] ? self.view.frame.size.width : self.view.frame.size.width, TOOL_BAR_HEIGHT)];

    self.toolBarScroll.backgroundColor = [UIColor clearColor];
    self.toolBarScroll.showsHorizontalScrollIndicator = NO;
    
}

- (void)createToolbarView{
    
    self.toolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, TOOL_BAR_HEIGHT)];
    self.toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.toolbarView.backgroundColor = [UIColor clearColor];
    [self.toolBarScroll addSubview:self.toolbarView];
    self.toolBarScroll.autoresizingMask = self.toolbar.autoresizingMask;
}

- (void)createParentHoldingView {
    
    //Background Toolbar
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    //Parent holding view
    self.toolbarHolder = [[UIView alloc] init];
    
    if (_alwaysShowToolbar) {
        self.toolbarHolder.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
    } else {
        self.toolbarHolder.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 44);
    }
    
    self.toolbarHolder.autoresizingMask = self.toolbar.autoresizingMask;
    [self.toolbarHolder addSubview:self.toolBarScroll];
    [self.toolbarHolder insertSubview:backgroundToolbar atIndex:0];
    
}

#pragma mark - Resources Section

- (void)loadResources {
    
    //Define correct bundle for loading resources
    NSBundle* bundle = [NSBundle bundleForClass:[ZSSRichTextEditor class]];
    
    //Create a string with the contents of editor.html
    NSString *filePath = [bundle pathForResource:@"editor" ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    
    //Add jQuery.js to the html file
    NSString *jquery = [bundle pathForResource:@"jQuery" ofType:@"js"];
    NSString *jqueryString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:jquery] encoding:NSUTF8StringEncoding];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- jQuery -->" withString:jqueryString];
    
    //Add JSBeautifier.js to the html file
    NSString *beautifier = [bundle pathForResource:@"JSBeautifier" ofType:@"js"];
    NSString *beautifierString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:beautifier] encoding:NSUTF8StringEncoding];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- jsbeautifier -->" withString:beautifierString];
    
    //Add ZSSRichTextEditor.js to the html file
    NSString *source = [bundle pathForResource:@"ZSSRichTextEditor" ofType:@"js"];
    NSString *jsString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:source] encoding:NSUTF8StringEncoding];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--editor-->" withString:jsString];
    
    [self.editorView loadHTMLString:htmlString baseURL:self.baseURL];
    self.resourcesLoaded = YES;
    
}

#pragma mark - Toolbar Section

- (void)setEnabledToolbarItems:(NSArray *)enabledToolbarItems {
    
    _enabledToolbarItems = enabledToolbarItems;
    [self buildToolbar];
    
}



- (void)setToolbarItemTintColor:(UIColor *)toolbarItemTintColor {
    
    _toolbarItemTintColor = toolbarItemTintColor;
    
    // Update the color
    for (ZSSBarButtonItem *item in self.toolbar.items) {
        item.tintColor = [self barButtonItemDefaultColor];
    }
    self.keyboardItem.tintColor = toolbarItemTintColor;
    
}


- (void)setToolbarItemSelectedTintColor:(UIColor *)toolbarItemSelectedTintColor {
    
    _toolbarItemSelectedTintColor = toolbarItemSelectedTintColor;
    
}



- (void)buildToolbar {
    
    NSBundle* bundle = [NSBundle bundleForClass:[ZSSRichTextEditor class]];
    
    float width = [UIScreen mainScreen].bounds.size.width / 6.0;
    
    
    UIButton *voice = [UIButton buttonWithType:UIButtonTypeCustom];
    voice.frame = CGRectMake(width * 0, 0, width, 49);
    [voice setImage:[UIImage imageNamed:@"t1.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [voice setImage:[UIImage imageNamed:@"t1.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [voice addTarget:self action:@selector(_voice) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:voice];
    
    UIButton *select = [UIButton buttonWithType:UIButtonTypeCustom];
    select.frame = CGRectMake(width * 1, 0, width, 49);
    [select setImage:[UIImage imageNamed:@"t2.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [select setImage:[UIImage imageNamed:@"t2.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [select addTarget:self action:@selector(_select) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:select];
    
    
     UIButton *textStyle = [UIButton buttonWithType:UIButtonTypeCustom];
     textStyle.frame = CGRectMake(width * 2, 0, width, 49);
     [textStyle setImage:[UIImage imageNamed:@"t3.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
     [textStyle setImage:[UIImage imageNamed:@"t3.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
     [textStyle addTarget:self action:@selector(_textStyle) forControlEvents:UIControlEventTouchUpInside];
    self.textStyleButton = textStyle;
     [self.toolbarView addSubview:textStyle];
     UIButton *size = [UIButton buttonWithType:UIButtonTypeCustom];
     size.frame = CGRectMake(width * 3, 0, width, 49);
     [size setImage:[UIImage imageNamed:@"t4.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
     [size setImage:[UIImage imageNamed:@"t4.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
     [size addTarget:self action:@selector(_textSize) forControlEvents:UIControlEventTouchUpInside];
    self.textSizeButton = size;
     [self.toolbarView addSubview:size];
     
     UIButton *alignment = [UIButton buttonWithType:UIButtonTypeCustom];
     alignment.frame = CGRectMake(width * 4, 0, width, 49);
     [alignment setImage:[UIImage imageNamed:@"t5.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
     [alignment setImage:[UIImage imageNamed:@"t5.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
     [alignment addTarget:self action:@selector(_textAlignment) forControlEvents:UIControlEventTouchUpInside];
    self.textAlignmentButton = alignment;
     [self.toolbarView addSubview:alignment];
     
     UIButton *color = [UIButton buttonWithType:UIButtonTypeCustom];
     color.frame = CGRectMake(width * 5, 0, width, 49);
     [color setImage:[UIImage imageNamed:@"t6.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
     [color setImage:[UIImage imageNamed:@"t6.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
     [color addTarget:self action:@selector(_textColor) forControlEvents:UIControlEventTouchUpInside];
    color.imageView.clipsToBounds = YES;
    color.imageView.layer.cornerRadius = 6.0f;
    self.textColorButton = color;
     [self.toolbarView addSubview:color];
    [self.toolBarScroll addSubview:self.toolbarView];
}


#pragma mark - Editor Modification Section

- (void)setCSS:(NSString *)css {
    
    self.customCSS = css;
    
    if (self.editorLoaded) {
        [self updateCSS];
    }
    
}

- (void)updateCSS {
    
    if (self.customCSS != NULL && [self.customCSS length] != 0) {
        
        NSString *js = [NSString stringWithFormat:@"zss_editor.setCustomCSS(\"%@\");", self.customCSS];
        [self.editorView stringByEvaluatingJavaScriptFromString:js];
        
    }
    
}

- (void)setPlaceholderText {
    
    //Call the setPlaceholder javascript method if a placeholder has been set
    if (self.placeholder != NULL && [self.placeholder length] != 0) {
    
        NSString *js = [NSString stringWithFormat:@"zss_editor.setPlaceholder(\"%@\");", self.placeholder];
        [self.editorView stringByEvaluatingJavaScriptFromString:js];
        
    }
    
}

- (void)setFooterHeight:(float)footerHeight {
    
    //Call the setFooterHeight javascript method
    NSString *js = [NSString stringWithFormat:@"zss_editor.setFooterHeight(\"%f\");", footerHeight];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
    
}

- (void)setContentHeight:(float)contentHeight {
    
    //Call the contentHeight javascript method
    NSString *js = [NSString stringWithFormat:@"zss_editor.contentHeight = %f;", contentHeight];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
    
}

#pragma mark - Editor Interaction

- (void)focusTextEditor {
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    NSString *js = [NSString stringWithFormat:@"zss_editor.focusEditor();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)blurTextEditor {
    NSString *js = [NSString stringWithFormat:@"zss_editor.blurEditor();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)setHTML:(NSString *)html {
    
    self.internalHTML = html;
    
    if (self.editorLoaded) {
        [self updateHTML];
    }
    
}

- (void)updateHTML {
    
    NSString *html = self.internalHTML;
    self.sourceView.text = html;
    NSString *cleanedHTML = [self removeQuotesFromHTML:self.sourceView.text];
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.setHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (NSString *)getHTML {
    
    NSString *html = [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getHTML();"];
    html = [self removeQuotesFromHTML:html];
    html = [self tidyHTML:html];
    return html;
    
}


- (void)insertHTML:(NSString *)html {
    
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (NSString *)getText {
    
    return [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getText();"];
    
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)showHTMLSource:(ZSSBarButtonItem *)barButtonItem {
    if (self.sourceView.hidden) {
        self.sourceView.text = [self getHTML];
        self.sourceView.hidden = NO;
        barButtonItem.tintColor = [UIColor blackColor];
        self.editorView.hidden = YES;
        [self enableToolbarItems:NO];
    } else {
        [self setHTML:self.sourceView.text];
        barButtonItem.tintColor = [self barButtonItemDefaultColor];
        self.sourceView.hidden = YES;
        self.editorView.hidden = NO;
        [self enableToolbarItems:YES];
    }
}

/*
- (void)removeFormat {
    NSString *trigger = @"zss_editor.removeFormating();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignLeft {
    NSString *trigger = @"zss_editor.setJustifyLeft();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignCenter {
    NSString *trigger = @"zss_editor.setJustifyCenter();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignRight {
    NSString *trigger = @"zss_editor.setJustifyRight();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignFull {
    NSString *trigger = @"zss_editor.setJustifyFull();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setBold {
    NSString *trigger = @"zss_editor.setBold();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setItalic {
    NSString *trigger = @"zss_editor.setItalic();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSubscript {
    NSString *trigger = @"zss_editor.setSubscript();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnderline {
    NSString *trigger = @"zss_editor.setUnderline();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSuperscript {
    NSString *trigger = @"zss_editor.setSuperscript();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setStrikethrough {
    NSString *trigger = @"zss_editor.setStrikeThrough();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnorderedList {
    NSString *trigger = @"zss_editor.setUnorderedList();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOrderedList {
    NSString *trigger = @"zss_editor.setOrderedList();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setHR {
    NSString *trigger = @"zss_editor.setHorizontalRule();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setIndent {
    NSString *trigger = @"zss_editor.setIndent();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOutdent {
    NSString *trigger = @"zss_editor.setOutdent();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading1 {
    NSString *trigger = @"zss_editor.setHeading('h1');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading2 {
    NSString *trigger = @"zss_editor.setHeading('h2');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading3 {
    NSString *trigger = @"zss_editor.setHeading('h3');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading4 {
    NSString *trigger = @"zss_editor.setHeading('h4');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading5 {
    NSString *trigger = @"zss_editor.setHeading('h5');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading6 {
    NSString *trigger = @"zss_editor.setHeading('h6');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)paragraph {
    NSString *trigger = @"zss_editor.setParagraph();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)showFontsPicker {
        
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    //Call picker
    ZSSFontsViewController *fontPicker = [ZSSFontsViewController cancelableFontPickerViewControllerWithFontFamily:ZSSFontFamilyDefault];
    fontPicker.delegate = self;
    [self.navigationController pushViewController:fontPicker animated:YES];
    
}

- (void)setSelectedFontFamily:(ZSSFontFamily)fontFamily {
    
    NSString *fontFamilyString;
    
    switch (fontFamily) {
        case ZSSFontFamilyDefault:
            fontFamilyString = @"Arial, Helvetica, sans-serif";
            break;
        
        case ZSSFontFamilyGeorgia:
            fontFamilyString = @"Georgia, serif";
            break;
        
        case ZSSFontFamilyPalatino:
            fontFamilyString = @"Palatino Linotype, Book Antiqua, Palatino, serif";
            break;
        
        case ZSSFontFamilyTimesNew:
            fontFamilyString = @"Times New Roman, Times, serif";
            break;
        
        case ZSSFontFamilyTrebuchet:
            fontFamilyString = @"Trebuchet MS, Helvetica, sans-serif";
            break;
        
        case ZSSFontFamilyVerdana:
            fontFamilyString = @"Verdana, Geneva, sans-serif";
            break;
        
        case ZSSFontFamilyCourierNew:
            fontFamilyString = @"Courier New, Courier, monospace";
            break;
        
        default:
            fontFamilyString = @"Arial, Helvetica, sans-serif";
            break;
    }
    
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.setFontFamily(\"%@\");", fontFamilyString];

    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (void)textColor {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 1;
    colorPicker.title = NSLocalizedString(@"Text Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
    
}

- (void)bgColor {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 2;
    colorPicker.title = NSLocalizedString(@"BG Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
    
}

- (void)setSelectedColor:(UIColor*)color tag:(int)tag {
    
    NSString *hex = [NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)];
    NSString *trigger;
    if (tag == 1) {
        trigger = [NSString stringWithFormat:@"zss_editor.setTextColor(\"%@\");", hex];
    } else if (tag == 2) {
        trigger = [NSString stringWithFormat:@"zss_editor.setBackgroundColor(\"%@\");", hex];
    }
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (void)undo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.undo();"];
}

- (void)redo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.redo();"];
}

- (void)insertLink {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Show the dialog for inserting or editing a link
    [self showInsertLinkDialogWithLink:self.selectedLinkURL title:self.selectedLinkTitle];
    
}


- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedLinkURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png" inBundle:[NSBundle bundleForClass:[ZSSRichTextEditor class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertURLAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Title", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (title) {
                textField.text = title;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *linkURL = [alertController.textFields objectAtIndex:0];
            UITextField *title = [alertController.textFields objectAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
                //NSLog(@"insert link");
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
            [self focusTextEditor];
        }]];
        [self presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 2;
        UITextField *linkURL = [self.alertView textFieldAtIndex:0];
        linkURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            linkURL.text = url;
        }
        
        linkURL.rightView = am;
        linkURL.rightViewMode = UITextFieldViewModeAlways;
        
        UITextField *alt = [self.alertView textFieldAtIndex:1];
        alt.secureTextEntry = NO;
        alt.placeholder = NSLocalizedString(@"Title", nil);
        if (title) {
            alt.text = title;
        }
        
        [self.alertView show];
    }
    
}
//*/

- (void)insertLink:(NSString *)url title:(NSString *)title {
    
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}


- (void)updateLink:(NSString *)url title:(NSString *)title {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)dismissAlertView {
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:YES];
}

- (void)addCustomToolbarItemWithButton:(UIButton *)button {
    
    if(self.customBarButtonItems == nil)
    {
        self.customBarButtonItems = [NSMutableArray array];
    }
    
    button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:28.5f];
    [button setTitleColor:[self barButtonItemDefaultColor] forState:UIControlStateNormal];
    [button setTitleColor:[self barButtonItemSelectedDefaultColor] forState:UIControlStateHighlighted];
    
    ZSSBarButtonItem *barButtonItem = [[ZSSBarButtonItem alloc] initWithCustomView:button];
    
    [self.customBarButtonItems addObject:barButtonItem];
    
    [self buildToolbar];
}

- (void)addCustomToolbarItem:(ZSSBarButtonItem *)item {
    
    if(self.customZSSBarButtonItems == nil)
    {
        self.customZSSBarButtonItems = [NSMutableArray array];
    }
    [self.customZSSBarButtonItems addObject:item];
    
    [self buildToolbar];
}


- (void)removeLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.unlink();"];
}

- (void)quickLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.quickLink();"];
}

- (void)insertImage {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    [self showInsertImageDialogWithLink:self.selectedImageURL alt:self.selectedImageAlt];
    
}

- (void)insertImageFromDevice {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    [self showInsertImageDialogFromDeviceWithScale:self.selectedImageScale alt:self.selectedImageAlt];
    
}

- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedImageURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png" inBundle:[NSBundle bundleForClass:[ZSSRichTextEditor class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertImageAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Alt", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (alt) {
                textField.text = alt;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *imageURL = [alertController.textFields objectAtIndex:0];
            UITextField *alt = [alertController.textFields objectAtIndex:1];
            if (!self.selectedImageURL) {
                [self insertImage:imageURL.text alt:alt.text];
            } else {
                [self updateImage:imageURL.text alt:alt.text];
            }
            [self focusTextEditor];
        }]];
        [self presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 1;
        UITextField *imageURL = [self.alertView textFieldAtIndex:0];
        imageURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            imageURL.text = url;
        }
        
        imageURL.rightView = am;
        imageURL.rightViewMode = UITextFieldViewModeAlways;
        imageURL.clearButtonMode = UITextFieldViewModeAlways;
        
        UITextField *alt1 = [self.alertView textFieldAtIndex:1];
        alt1.secureTextEntry = NO;
        alt1.placeholder = NSLocalizedString(@"Alt", nil);
        alt1.clearButtonMode = UITextFieldViewModeAlways;
        if (alt) {
            alt1.text = alt;
        }
        
        [self.alertView show];
    }
    
}

- (void)showInsertImageDialogFromDeviceWithScale:(CGFloat)scale alt:(NSString *)alt {
    
    // Insert button title
    NSString *insertButtonTitle = !self.selectedImageURL ? NSLocalizedString(@"Pick Image", nil) : NSLocalizedString(@"Pick New Image", nil);
    
    //If the OS version supports the new UIAlertController go for it. Otherwise use the old UIAlertView
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Image From Device", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        //Add alt text field
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Alt", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (alt) {
                textField.text = alt;
            }
        }];
        
        //Add scale text field
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            textField.placeholder = NSLocalizedString(@"Image scale, 0.5 by default", nil);
            textField.keyboardType = UIKeyboardTypeDecimalPad;
        }];
        
        //Cancel action
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        
        //Insert action
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *textFieldAlt = [alertController.textFields objectAtIndex:0];
            UITextField *textFieldScale = [alertController.textFields objectAtIndex:1];

            self.selectedImageScale = [textFieldScale.text floatValue]?:kDefaultScale;
            self.selectedImageAlt = textFieldAlt.text?:@"";
            
            [self presentViewController:self.imagePicker animated:YES completion:nil];

        }]];
        
        [self presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 3;
        
        UITextField *textFieldAlt = [self.alertView textFieldAtIndex:0];
        textFieldAlt.secureTextEntry = NO;
        textFieldAlt.placeholder = NSLocalizedString(@"Alt", nil);
        textFieldAlt.clearButtonMode = UITextFieldViewModeAlways;
        if (alt) {
            textFieldAlt.text = alt;
        }
        
        UITextField *textFieldScale = [self.alertView textFieldAtIndex:1];
        textFieldScale.placeholder = NSLocalizedString(@"Image scale, 0.5 by default", nil);
        textFieldScale.keyboardType = UIKeyboardTypeDecimalPad;
        
        [self.alertView show];
    }
    
}

- (void)insertImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)updateImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)insertImageBase64String:(NSString *)imageBase64String alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertImageBase64String(\"%@\", \"%@\");", imageBase64String, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)updateImageBase64String:(NSString *)imageBase64String alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateImageBase64String(\"%@\", \"%@\");", imageBase64String, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)updateToolViewWithButtonName:(NSString *)name {

    NSBundle* bundle = [NSBundle bundleForClass:[ZSSRichTextEditor class]];

    NSArray *itemNames = [name componentsSeparatedByString:@","];
    
    NSString *styleStr = @"t3.png";
    if ([itemNames containsObject:@"bold"] && [itemNames containsObject:@"italic"]) {
        
        styleStr = @"Text-bold-tilt.png";
    }
    else if ([itemNames containsObject:@"bold"]) {
        
       styleStr = @"t31点击.png";
    }
    else if ([itemNames containsObject:@"italic"]) {
        
       styleStr = @"t33点击.png";
    }
    [self.textStyleButton setImage:[UIImage imageNamed:styleStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.textStyleButton setImage:[UIImage imageNamed:styleStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    
    NSString *alignmentStr = @"t5.png";
    if ([itemNames containsObject:@"justifyLeft"]) {
        
      alignmentStr = @"t5点击.png";
    }
    else if ([itemNames containsObject:@"justifyCenter"]) {
        
       alignmentStr = @"t52点击.png";
    }
    else if ([itemNames containsObject:@"justifyRight"]) {
        
     alignmentStr = @"t51点击.png";
    }
    else{
    
    }
    [self.textAlignmentButton setImage:[UIImage imageNamed:alignmentStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.textAlignmentButton setImage:[UIImage imageNamed:alignmentStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    
    UIImage *image = [UIImage imageNamed:@"t6"];
    NSString *colorStr = @"";
    for (NSString *item in itemNames) {
        
        if ([item hasPrefix:@"#"]) {
            
            NSLog(@"%@", item);
            colorStr = [item stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
        }
    }
    
    if (colorStr.length > 0) {
        
        long colorLong = strtoul([colorStr cStringUsingEncoding:NSUTF8StringEncoding], 0, 16);
        
        UIColor *color = UIColorFromRGB(colorLong);
        image = [self createImageWithColor:color];
    }
    
    [self.textColorButton setImage:image forState:UIControlStateNormal];
    [self.textColorButton setImage:image forState:UIControlStateSelected];
    
}

- (UIImage *) createImageWithColor: (UIColor *) color
{
    CGRect rect = CGRectMake(0.0f,0.0f,22.0f,22.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context =UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *myImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return myImage;
}
- (void)updateToolBarWithButtonName:(NSString *)name {
    
   
    // Items that are enabled
    NSArray *itemNames = [name componentsSeparatedByString:@","];
    
    // Special case for link
    NSMutableArray *itemsModified = [[NSMutableArray alloc] init];
    for (NSString *linkItem in itemNames) {
        NSString *updatedItem = linkItem;
        if ([linkItem hasPrefix:@"link:"]) {
            updatedItem = @"link";
            self.selectedLinkURL = [linkItem stringByReplacingOccurrencesOfString:@"link:" withString:@""];
        } else if ([linkItem hasPrefix:@"link-title:"]) {
            self.selectedLinkTitle = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"link-title:" withString:@""]];
        } else if ([linkItem hasPrefix:@"image:"]) {
            updatedItem = @"image";
            self.selectedImageURL = [linkItem stringByReplacingOccurrencesOfString:@"image:" withString:@""];
        } else if ([linkItem hasPrefix:@"image-alt:"]) {
            self.selectedImageAlt = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"image-alt:" withString:@""]];
        } else {
            self.selectedImageURL = nil;
            self.selectedImageAlt = nil;
            self.selectedLinkURL = nil;
            self.selectedLinkTitle = nil;
        }
        [itemsModified addObject:updatedItem];
    }
    itemNames = [NSArray arrayWithArray:itemsModified];
    
    self.editorItemsEnabled = itemNames;
    
    // Highlight items
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if ([itemNames containsObject:item.label]) {
            item.tintColor = [self barButtonItemSelectedDefaultColor];
        } else {
            item.tintColor = [self barButtonItemDefaultColor];
        }
    }
    
}


#pragma mark - UITextView Delegate

- (void)textViewDidChange:(UITextView *)textView {
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
    if ( overflow > 0 ) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
    
}


#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    
    NSString *urlString = [[request URL] absoluteString];
    //NSLog(@"web request");
    //NSLog(@"%@", urlString);
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    }
    else if ([urlString rangeOfString:@"callback://0/"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *className = [urlString stringByReplacingOccurrencesOfString:@"callback://0/" withString:@""];
        [self updateToolBarWithButtonName:className];
        [self updateToolViewWithButtonName:className];
        
    } else if ([urlString rangeOfString:@"debug://"].location != NSNotFound) {
        
        NSLog(@"Debug Found");
        
        // We recieved the callback
        NSString *debug = [urlString stringByReplacingOccurrencesOfString:@"debug://" withString:@""];
        debug = [debug stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
        NSLog(@"%@", debug);
        
    } else if ([urlString rangeOfString:@"scroll://"].location != NSNotFound) {
        
        NSInteger position = [[urlString stringByReplacingOccurrencesOfString:@"scroll://" withString:@""] integerValue];
        [self editorDidScrollWithPosition:position];
        
    }
    
    return YES;
    
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.editorLoaded = YES;

    if (!self.internalHTML) {
        self.internalHTML = @"";
    }
    [self updateHTML];

    if(self.placeholder) {
        [self setPlaceholderText];
    }
    
    if (self.customCSS) {
        [self updateCSS];
    }

    if (self.shouldShowKeyboard) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self focusTextEditor];
        });
    }
    
    /*
     
     Callback for when text is changed, solution posted by richardortiz84 https://github.com/nnhubbard/ZSSRichTextEditor/issues/5
     
     */
    JSContext *ctx = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    ctx[@"contentUpdateCallback"] = ^(JSValue *msg) {
        
        NSLog(@"%@", msg);
        if (_receiveEditorDidChangeEvents) {
            
            [self editorDidChangeWithText:[self getText] andHTML:[self getHTML]];
            
        }
        
        [self checkForMentionOrHashtagInText:[self getText]];
        
    };
    [ctx evaluateScript:@"document.getElementById('zss_editor_content').addEventListener('input', contentUpdateCallback, false);"];
    
}

#pragma mark - Mention & Hashtag Support Section

- (void)checkForMentionOrHashtagInText:(NSString *)text {
    
    if ([text containsString:@" "] && [text length] > 0) {
        
        NSString *lastWord = nil;
        NSString *matchedWord = nil;
        BOOL ContainsHashtag = NO;
        BOOL ContainsMention = NO;
        
        NSRange range = [text rangeOfString:@" " options:NSBackwardsSearch];
        lastWord = [text substringFromIndex:range.location];
        
        if (lastWord != nil) {
        
            //Check if last word typed starts with a #
            NSRegularExpression *hashtagRegex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:nil];
            NSArray *hashtagMatches = [hashtagRegex matchesInString:lastWord options:0 range:NSMakeRange(0, lastWord.length)];
            
            for (NSTextCheckingResult *match in hashtagMatches) {
                
                NSRange wordRange = [match rangeAtIndex:1];
                NSString *word = [lastWord substringWithRange:wordRange];
                matchedWord = word;
                ContainsHashtag = YES;
                
            }
            
            if (!ContainsHashtag) {
                
                //Check if last word typed starts with a @
                NSRegularExpression *mentionRegex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:nil];
                NSArray *mentionMatches = [mentionRegex matchesInString:lastWord options:0 range:NSMakeRange(0, lastWord.length)];
                
                for (NSTextCheckingResult *match in mentionMatches) {
                    
                    NSRange wordRange = [match rangeAtIndex:1];
                    NSString *word = [lastWord substringWithRange:wordRange];
                    matchedWord = word;
                    ContainsMention = YES;
                    
                }
                
            }
            
        }
        
        if (ContainsHashtag) {
            
            [self hashtagRecognizedWithWord:matchedWord];
            
        }
        
        if (ContainsMention) {
            
            [self mentionRecognizedWithWord:matchedWord];
            
        }
        
    }
    
}

#pragma mark - Callbacks

//Blank implementation
- (void)editorDidScrollWithPosition:(NSInteger)position {}

//Blank implementation
- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html  {}

//Blank implementation
- (void)hashtagRecognizedWithWord:(NSString *)word {}

//Blank implementation
- (void)mentionRecognizedWithWord:(NSString *)word {}


#pragma mark - AlertView

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    if (alertView.tag == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        if ([textField.text length] == 0 || [textField2.text length] == 0) {
            return NO;
        }
    } else if (alertView.tag == 2) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0) {
            return NO;
        }
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            UITextField *imageURL = [alertView textFieldAtIndex:0];
            UITextField *alt = [alertView textFieldAtIndex:1];
            if (!self.selectedImageURL) {
                [self insertImage:imageURL.text alt:alt.text];
            } else {
                [self updateImage:imageURL.text alt:alt.text];
            }
        }
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            UITextField *linkURL = [alertView textFieldAtIndex:0];
            UITextField *title = [alertView textFieldAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
        }
    } else if (alertView.tag == 3) {
        if (buttonIndex == 1) {
            UITextField *textFieldAlt = [alertView textFieldAtIndex:0];
            UITextField *textFieldScale = [alertView textFieldAtIndex:1];
            
            self.selectedImageScale = [textFieldScale.text floatValue]?:kDefaultScale;
            self.selectedImageAlt = textFieldAlt.text?:@"";
            
            [self presentViewController:self.imagePicker animated:YES completion:nil];

        }
    }
}


#pragma mark - Asset Picker

- (void)showInsertURLAlternatePicker {
    // Blank method. User should implement this in their subclass
}


- (void)showInsertImageAlternatePicker {
    // Blank method. User should implement this in their subclass
}

#pragma mark - Image Picker Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    //Dismiss the Image Picker
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info{

    UIImage *selectedImage = info[UIImagePickerControllerEditedImage]?:info[UIImagePickerControllerOriginalImage];
    
    //Scale the image
    CGSize targetSize = CGSizeMake(selectedImage.size.width * self.selectedImageScale, selectedImage.size.height * self.selectedImageScale);
    UIGraphicsBeginImageContext(targetSize);
    [selectedImage drawInRect:CGRectMake(0,0,targetSize.width,targetSize.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //Compress the image, as it is going to be encoded rather than linked
    NSData *scaledImageData = UIImageJPEGRepresentation(scaledImage, kJPEGCompression);
    
    //Encode the image data as a base64 string
    NSString *imageBase64String = [scaledImageData base64EncodedStringWithOptions:0];
    
    //Decide if we have to insert or update
    if (!self.imageBase64String) {
        [self insertImageBase64String:imageBase64String alt:self.selectedImageAlt];
    } else {
        [self updateImageBase64String:imageBase64String alt:self.selectedImageAlt];
    }
    
    self.imageBase64String = imageBase64String;

    //Dismiss the Image Picker
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Keyboard status

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    
    // Orientation
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // User Info
    NSDictionary *info = notification.userInfo;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Toolbar Sizes
    CGFloat sizeOfToolbar = self.toolbarHolder.frame.size.height;
    
    // Keyboard Size
    //Checks if IOS8, gets correct keyboard height
    CGFloat keyboardHeight = UIInterfaceOrientationIsLandscape(orientation) ? ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.000000) ? keyboardEnd.size.height : keyboardEnd.size.width : keyboardEnd.size.height;
    
    // Correct Curve
    UIViewAnimationOptions animationOptions = curve << 16;
    
    const int extraHeight = 10;
    
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            
            // Toolbar
            CGRect frame = self.toolbarHolder.frame;
            frame.origin.y = self.view.frame.size.height - (keyboardHeight + sizeOfToolbar);
            self.toolbarHolder.frame = frame;
            
            // Editor View
            CGRect editorFrame = self.editorView.frame;
            editorFrame.size.height = (self.view.frame.size.height - keyboardHeight) - sizeOfToolbar - extraHeight;
            self.editorView.frame = editorFrame;
            self.editorViewFrame = self.editorView.frame;
            self.editorView.scrollView.contentInset = UIEdgeInsetsZero;
            self.editorView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
            
            // Source View
            CGRect sourceFrame = self.sourceView.frame;
            sourceFrame.size.height = (self.view.frame.size.height - keyboardHeight) - sizeOfToolbar - extraHeight;
            self.sourceView.frame = sourceFrame;
            
            // Provide editor with keyboard height and editor view height
            [self setFooterHeight:(keyboardHeight - 8)];
            [self setContentHeight: self.editorViewFrame.size.height];
            
        } completion:nil];
        
    } else {
        
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            
            CGRect frame = self.toolbarHolder.frame;
            
            if (_alwaysShowToolbar) {
                frame.origin.y = self.view.frame.size.height - sizeOfToolbar;
            } else {
                frame.origin.y = self.view.frame.size.height + keyboardHeight;
            }
            
            self.toolbarHolder.frame = frame;
            
            // Editor View
            CGRect editorFrame = self.editorView.frame;
            
            if (_alwaysShowToolbar) {
                editorFrame.size.height = ((self.view.frame.size.height - sizeOfToolbar) - extraHeight);
            } else {
                editorFrame.size.height = self.view.frame.size.height;
            }
            
            self.editorView.frame = editorFrame;
            self.editorViewFrame = self.editorView.frame;
            self.editorView.scrollView.contentInset = UIEdgeInsetsZero;
            self.editorView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
            
            // Source View
            CGRect sourceFrame = self.sourceView.frame;
            
            if (_alwaysShowToolbar) {
                sourceFrame.size.height = ((self.view.frame.size.height - sizeOfToolbar) - extraHeight);
            } else {
                sourceFrame.size.height = self.view.frame.size.height;
            }
            
            self.sourceView.frame = sourceFrame;
            
            [self setFooterHeight:0];
            [self setContentHeight:self.editorViewFrame.size.height];
            
        } completion:nil];
        
    }
    
}


#pragma mark - Utilities

- (NSString *)removeQuotesFromHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    html = [html stringByReplacingOccurrencesOfString:@"“" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"”" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"\r"  withString:@"\\r"];
    html = [html stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"];
    return html;
}


- (NSString *)tidyHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"<br />"];
    html = [html stringByReplacingOccurrencesOfString:@"<hr>" withString:@"<hr />"];
    if (self.formatHTML) {
        html = [self.editorView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"style_html(\"%@\");", html]];
    }
    return html;
}


- (UIColor *)barButtonItemDefaultColor {
    
    if (self.toolbarItemTintColor) {
        return self.toolbarItemTintColor;
    }
    
    return [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
}


- (UIColor *)barButtonItemSelectedDefaultColor {
    
    if (self.toolbarItemSelectedTintColor) {
        return self.toolbarItemSelectedTintColor;
    }
    
    return [UIColor blackColor];
}


- (BOOL)isIpad {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}


- (NSString *)stringByDecodingURLFormat:(NSString *)string {
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (void)enableToolbarItems:(BOOL)enable {
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if (![item.label isEqualToString:@"source"]) {
            item.enabled = enable;
        }
    }
}

#pragma mark - Memory Warning Section
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark -
#pragma mark - canPerformAction
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{

    [UIPasteboard generalPasteboard].string = self.pasteBoardText;
    return [super canPerformAction:action withSender:sender];
}


@end
