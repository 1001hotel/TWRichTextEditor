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

#import <iflyMSC/iflyMSC.h>
#import <iflyMSC/iflyMSC.h>
#import "IATConfig.h"
#import "ISRDataHelper.h"
#import <FreshLoadingView.h>

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#define TOOL_BAR_HEIGHT    49
#define CORNER_RADIUS_7     7

#define SCREEN_SIZE         [UIScreen mainScreen].bounds.size

#define TOOL_ITEM_NUM       7.0

#define NAVIGATIONBAR_HEIGHT                44
#define NAVIGATIONBAR_LABEL_WIDTH           160
#define NAVIGATIONBAR_BUTTON_HEIGHT         44
#define NAVIGATIONBAR_BUTTON_TEXT_WIDTH     24
#define NAVIGATIONBAR_BUTTON_FONT_SIZE      16




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
<
IFlySpeechRecognizerDelegate,
IFlyRecognizerViewDelegate,
IFlyPcmRecorderDelegate
>
{
    
    float _keyboardOringalY;
    
    float _keyBoardHeight;
    
    BOOL _isActionStyle;
    BOOL _isActionColor;
    BOOL _isActionAlignment;
    FreshLoadingView *_loadingView;
}

@property (nonatomic, strong) NSString *pcmFilePath;//音频文件路径
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//不带界面的识别对象
@property (nonatomic, strong) IFlyRecognizerView *iflyRecognizerView;//带界面的识别对象
@property (nonatomic, strong) IFlyDataUploader *uploader;//数据上传对象

@property (nonatomic, strong) NSString * result;
@property (nonatomic, assign) BOOL isCanceled;

@property (nonatomic,strong) IFlyPcmRecorder *pcmRecorder;//录音器，用于音频流识别的数据传入
@property (nonatomic,assign) BOOL isStreamRec;//是否是音频流识别
@property (nonatomic,assign) BOOL isBeginOfSpeech;//是否返回BeginOfSpeech回调

@property (nonatomic,assign) BOOL isRecording;

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

@property (nonatomic, copy) NSString *pasteBoardText;
@property (nonatomic, copy) NSString *lastHtmlString;



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



@end

@implementation ZSSRichTextEditor (private)




- (UIImage *)createImageWithColor:(UIColor *) color{
    
    CGRect rect = CGRectMake(0.0f,0.0f,22.0f,22.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context =UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *myImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return myImage;
}

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


#pragma mark -
#pragma mark - keyboardNotification
- (void)keyboardWasShown:(NSNotification*)aNotification{
    //键盘高度
    CGRect keyBoardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    _keyboardOringalY = keyBoardFrame.origin.y;
    _keyBoardHeight = keyBoardFrame.size.height;

    
}
- (void)keyboardWillBeHidden:(NSNotification*)aNotification{
    
    CGRect keyBoardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    _keyboardOringalY = keyBoardFrame.origin.y;
//    _keyBoardHeight = 0;

}
- (void)keyboardDidChangeFrame:(NSNotification*)aNotification{
    
    CGRect keyBoardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    _keyboardOringalY = keyBoardFrame.origin.y;
}


#pragma mark -
#pragma mark - voice
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
    }
    
    
    self.voiceView.backgroundColor = [UIColor whiteColor];
    [self.toolBarScroll addSubview:self.voiceView];
    
    [self startBtnHandler:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        
    }];
    
    
    
    
}
- (IBAction)startBtnHandler:(id)sender {
    
    if (self.isRecording) {
        
        return;
    }
    
    
    if ([IATConfig sharedInstance].haveView == NO) {//无界面
        
        //        [_textView resignFirstResponder];
        self.isCanceled = NO;
        self.isStreamRec = NO;
        
        if(self.iFlySpeechRecognizer == nil)
        {
            [self initRecognizer];
        }
        
        [self.iFlySpeechRecognizer cancel];
        
        //设置音频来源为麦克风
        [self.iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [self.iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
        [self.iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        [self.iFlySpeechRecognizer setDelegate:self];
        
        BOOL ret = [self.iFlySpeechRecognizer startListening];
        
        if (ret) {
            self.isRecording = YES;
            
        }else{
            //xry
            //            [self alertMessage:@"启动识别服务失败，请稍后重试" delayFordisimissComplete:1.0f];
        }
    }else {
        
        if(self.iflyRecognizerView == nil)
        {
            [self initRecognizer ];
        }
        
        //        [_textView resignFirstResponder];
        
        //设置音频来源为麦克风
        [self.iflyRecognizerView setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [self.iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
        [self.iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        BOOL ret = [self.iflyRecognizerView start];
        if (ret) {
            //            [_startRecBtn setEnabled:NO];
            //            [_audioStreamBtn setEnabled:NO];
            //            [_upWordListBtn setEnabled:NO];
            //            [_upContactBtn setEnabled:NO];
        }
    }
    
}
/**
 停止录音
 *****/
- (IBAction)stopBtnHandler:(id)sender {
    
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        
        [self.pcmRecorder stop];
        //        [self alertMessage:@"停止录音" delayForAutoComplete:1 completion:nil];
    }
    self.isRecording = NO;
    
    [self.iFlySpeechRecognizer stopListening];
    //    [_textView resignFirstResponder];
}
/**
 取消听写
 *****/
- (IBAction)cancelBtnHandler:(id)sender {
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        
        [self.pcmRecorder stop];
    }
    
    self.isCanceled = YES;
    self.isRecording = NO;
    [self.iFlySpeechRecognizer cancel];
}
/**
 设置识别参数
 ****/
- (void)initRecognizer{
    
    if ([IATConfig sharedInstance].haveView == NO) {//无界面
        
        //单例模式，无UI的实例
        if (self.iFlySpeechRecognizer == nil) {
            self.iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
            
            [self.iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
            
            //设置听写模式
            [self.iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        }
        self.iFlySpeechRecognizer.delegate = self;
        
        if (self.iFlySpeechRecognizer != nil) {
            IATConfig *instance = [IATConfig sharedInstance];
            
            //设置最长录音时间
            [self.iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            //设置后端点
            [self.iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            //设置前端点
            [self.iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            //网络等待时间
            [self.iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
            
            //设置采样率，推荐使用16K
            [self.iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
            
            if ([instance.language isEqualToString:[IATConfig chinese]]) {
                //设置语言
                [self.iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
                //设置方言
                [self.iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            }else if ([instance.language isEqualToString:[IATConfig english]]) {
                [self.iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            }
            //设置是否返回标点符号
            [self.iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
            
        }
        
        //初始化录音器
        if (self.pcmRecorder == nil)
        {
            self.pcmRecorder = [IFlyPcmRecorder sharedInstance];
        }
        
        self.pcmRecorder.delegate = self;
        
        [self.pcmRecorder setSample:[IATConfig sharedInstance].sampleRate];
        
        [self.pcmRecorder setSaveAudioPath:nil];    //不保存录音文件
        
    }else  {//有界面
        
        //单例模式，UI的实例
        if (self.iflyRecognizerView == nil) {
            //UI显示剧中
            self.iflyRecognizerView= [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
            
            [self.iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
            
            //设置听写模式
            [self.iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
            
        }
        self.iflyRecognizerView.delegate = self;
        
        if (self.iflyRecognizerView != nil) {
            IATConfig *instance = [IATConfig sharedInstance];
            //设置最长录音时间
            [self.iflyRecognizerView setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            //设置后端点
            [self.iflyRecognizerView setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            //设置前端点
            [self.iflyRecognizerView setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            //网络等待时间
            [self.iflyRecognizerView setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
            
            //设置采样率，推荐使用16K
            [self.iflyRecognizerView setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
            if ([instance.language isEqualToString:[IATConfig chinese]]) {
                //设置语言
                [self.iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
                //设置方言
                [self.iflyRecognizerView setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            }else if ([instance.language isEqualToString:[IATConfig english]]) {
                //设置语言
                [self.iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            }
            //设置是否返回标点符号
            [self.iflyRecognizerView setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
            
        }
    }
}
- (void)_done{
    
    [self stopBtnHandler:nil];
    
    if (self.voiceView.superview) {
        [self.voiceView removeFromSuperview];
    }
}


#pragma mark -
#pragma mark - recognitionText
- (void)_recognition{
    
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    UIViewController *vc = [AipGeneralVC ViewControllerWithDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark -
#pragma mark - selectText
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
        float oringalX = SCREEN_SIZE.width / TOOL_ITEM_NUM * 2 + SCREEN_SIZE.width / TOOL_ITEM_NUM / 2.0 - (width / 2.0);
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


#pragma mark -
#pragma mark - textStyle
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
        float oringalX = SCREEN_SIZE.width / TOOL_ITEM_NUM * 3 + SCREEN_SIZE.width / TOOL_ITEM_NUM / 2.0 - (width / 2.0);
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
    
    _isActionStyle = YES;
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


#pragma mark -
#pragma mark - textSize
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
        float oringalX = SCREEN_SIZE.width / TOOL_ITEM_NUM * 4 + SCREEN_SIZE.width / TOOL_ITEM_NUM / 2.0 - (width / 2.0);
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


#pragma mark -
#pragma mark - textAlignment
- (void)_textAlignment{
    
    _isActionAlignment = YES;
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
        float oringalX = SCREEN_SIZE.width / TOOL_ITEM_NUM * 5 + SCREEN_SIZE.width / TOOL_ITEM_NUM / 2.0 - (width / 2.0);
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


#pragma mark -
#pragma mark - textColor
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
        
        float width = SCREEN_SIZE.width;
        
        float height = 30 * 1 + 9;
        float oringalX = SCREEN_SIZE.width - width;
        float oringalY = _keyboardOringalY - 64 - height - TOOL_BAR_HEIGHT;
        
        if (!self.textColorView) {
            
            self.textColorView = [[RYIndicatorBackgroudView alloc] initWithFrame:CGRectMake(oringalX, oringalY, width, height) withRightDistance:SCREEN_SIZE.width / TOOL_ITEM_NUM / 3];
            
            NSArray *images = [NSArray arrayWithArray:self.textColorArray];
            
            float buttonWidth = width / 10;
            float buttonHeight = 30;
            
            for (int i = 0; i < images.count; i ++) {
                
                
                NSString *imagestr = [images objectAtIndex:i];
                
                CGRect rect = CGRectZero;
//                if (i < 10) {
//                    
                    rect = CGRectMake(buttonWidth * i, 0, buttonWidth, buttonHeight);
//                }
//                else{
//                    
//                    rect = CGRectMake(buttonWidth * (i - 7), 30, buttonWidth, buttonHeight);
//                }
                
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
    
    _isActionColor = YES;
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    NSArray *images = [NSArray arrayWithArray:self.textColorArray];
    
    if (sender.tag >= 100 && sender.tag - 100 < images.count) {
        
        NSString *imagestr = [images objectAtIndex:sender.tag - 100];
        long colorLong = strtoul([imagestr cStringUsingEncoding:NSUTF8StringEncoding], 0, 16);
        
        UIColor *color = UIColorFromRGB(colorLong);
        NSString *hex = [NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)];
        
        UIImage *image = [self createImageWithColor:color];
        [self.textColorButton setImage:image forState:UIControlStateNormal];
        [self.textColorButton setImage:image forState:UIControlStateSelected];
        
        NSString *trigger = [NSString stringWithFormat:@"zss_editor.setTextColor(\"%@\");", hex];
        
        [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    }
}



- (void)_setAipOcr{
    
#pragma gallery
    [[AipOcrService shardService] authWithAK:@"dO3s3M785v8q5l2D8i8ne3yG" andSK:@"3o16M5QECFC8PVzwZdtlUXGCL1qLt3y4"];
    
#pragma test
    //[[AipOcrService shardService] authWithAK:@"BKahGmIO0h4qn6um2juGzRDR" andSK:@"hZHBi7k3k7wOvEEh9Sp2nCN7mjMFT6Xu"];

    
    /*
    // 授权方法2： 下载授权文件，添加至资源
    NSString *licenseFile = [[NSBundle mainBundle] pathForResource:@"aip" ofType:@"license"];
    NSData *licenseFileData = [NSData dataWithContentsOfFile:licenseFile];
    if(!licenseFileData) {
        [[[UIAlertView alloc] initWithTitle:@"授权失败" message:@"授权文件不存在" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    [[AipOcrService shardService] authWithLicenseFileData:licenseFileData];
    //*/
    
    /*
    // 授权方法3： 自行搭建服务器，分配token
    [[AipOcrService shardService] authWithToken:@"24.37a8f6e5c4d75d228a6d4c1b35a67a3e.2592000.1497587841.282335-9640420"];
    //*/
    
    
}


@end

/*
 
 ZSSRichTextEditor
 
 */
@implementation ZSSRichTextEditor

//Scale image from device
static CGFloat kJPEGCompression = 0.8;
static CGFloat kDefaultScale = 0.5;

#pragma mark -
#pragma mark - lifeCycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //Initialise variables
    self.editorLoaded = NO;
    self.receiveEditorDidChangeEvents = NO;
    self.alwaysShowToolbar = YES;
    self.shouldShowKeyboard = NO;
    self.formatHTML = YES;
    
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
//                           @"0xF7EF14",
                           @"0x22AD38",
                           @"0x03A1E9",
//                           @"0x181C62",
                           @"0x930883",
//                           @"0x956034",
                           @"0x6A3806",
                           @"0x000000",
                           @"0x595858",
                           @"0x898989",
                           @"0xCACACB",
//                           @"0xF0F0F0",
                           nil];
    
    [self.view addSubview:self.toolbarHolder];
    
    //Build the toolbar
    [self buildToolbar];
    
    //Load Resources
    if (!self.resourcesLoaded) {
        
        [self loadResources];
        
    }
    [self _setAipOcr];
    
    //初始化数据上传类
    self.uploader = [[IFlyDataUploader alloc] init];
    
    //demo录音文件保存路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    _pcmFilePath = [[NSString alloc] initWithFormat:@"%@",[cachePath stringByAppendingPathComponent:@"asr.pcm"]];
    
    self.isRecording = NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.htmlText.length == 0) {
        
        _isActionColor = NO;
        _isActionStyle = NO;
        _isActionAlignment = NO;
    }
    else{
    
        _isActionColor = YES;
        _isActionStyle = YES;
        _isActionAlignment = YES;
    }
}
- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    //Add observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    //Remove observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - public
- (void)alertMessage:(NSString *)message delayFordisimissComplete:(float)delay{
    if (delay<=0) {
        delay = 2.0f;
    }
    delay = 1.5f;
    
    
    CGFloat gapHeight = [UIScreen mainScreen].bounds.size.width * 100.0 / 375.0;
    __block UIView *alertDefineView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_SIZE.width * 0.25 * 0.5, self.view.frame.size.height - gapHeight - _keyBoardHeight, SCREEN_SIZE.width * 0.75, 30)];
    alertDefineView.backgroundColor = [UIColor colorWithRed:51 /255.0 green:51 /255.0 blue:51 /255.0 alpha:1];
    alertDefineView.alpha = 0;
    alertDefineView.layer.cornerRadius = 6;
    
    __block UILabel *alertLabel = [[UILabel alloc]initWithFrame:alertDefineView.frame];
    alertLabel.backgroundColor = [UIColor clearColor];
    alertLabel.textColor = [UIColor whiteColor];
    alertLabel.textAlignment = NSTextAlignmentCenter;
    alertLabel.font = [UIFont systemFontOfSize:15];
    alertLabel.numberOfLines = 0;
    alertLabel.alpha = 0;
    
    alertLabel.text = message;
    CGRect alterRect_0 = [message boundingRectWithSize:CGSizeMake(MAXFLOAT, alertLabel.frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil];
    alertDefineView.frame = CGRectMake((SCREEN_SIZE.width - alterRect_0.size.width - 30) * 0.5, self.view.frame.size.height-gapHeight - _keyBoardHeight, alterRect_0.size.width + 30, 30);
    alertDefineView.layer.cornerRadius = 6;
    alertLabel.frame = alertDefineView.frame;
    
    if (alterRect_0.size.width >= SCREEN_SIZE.width * 0.75) {
        CGRect alterRect_1 = [message boundingRectWithSize:CGSizeMake(SCREEN_SIZE.width * 0.75, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil];
        alertDefineView.frame = CGRectMake((SCREEN_SIZE.width - SCREEN_SIZE.width * 0.75 - 30) * 0.5, self.view.frame.size.height - gapHeight - (alterRect_1.size.height + 30 - 30) - _keyBoardHeight, SCREEN_SIZE.width * 0.75 + 20, alterRect_1.size.height + 20);
        alertDefineView.layer.cornerRadius = 6;
        alertLabel.frame = alertDefineView.frame;
    }
    [self.view addSubview:alertDefineView];
    [self.view addSubview:alertLabel];
    [self.view bringSubviewToFront:alertDefineView];
    [self.view bringSubviewToFront:alertLabel];
    
    [UIView animateWithDuration:0.2f animations:^{
        alertDefineView.alpha = 0.8;
        alertLabel.alpha =1;
    }completion:^(BOOL finished) {
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay/*延迟执行时间*/ * NSEC_PER_SEC));
        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2f animations:^{
                alertDefineView.alpha = 0;
                alertLabel.alpha = 0;
            }completion:^(BOOL finished) {
                alertDefineView = nil;
                alertLabel =nil;
                [alertDefineView removeFromSuperview];
                [alertLabel removeFromSuperview];
            }];;
        });
    }];
}


#pragma mark -
#pragma mark - Loading
- (void)startLoading{
    
    if (!_loadingView) {
        _loadingView = [[FreshLoadingView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    }
    
    if ([[NSThread mainThread] isMainThread]) {
        
        [_loadingView startAnimating];
        [self.view addSubview:_loadingView];
        [self.view bringSubviewToFront:_loadingView];
        @try {
            // 可能会出现崩溃的代码
            self.view.userInteractionEnabled = NO;
            
        }
        @catch (NSException *exception) {
            // 捕获到的异常exception
        }
        @finally {
            // 结果处理
        }
        
    }
    else{
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [_loadingView startAnimating];
            [self.view addSubview:_loadingView];
            [self.view bringSubviewToFront:_loadingView];
            @try {
                // 可能会出现崩溃的代码
                self.view.userInteractionEnabled = NO;
                
            }
            @catch (NSException *exception) {
                // 捕获到的异常exception
            }
            @finally {
                // 结果处理
            }
        });
    }
}
- (void)stopLoading{
    
    
    if ([[NSThread mainThread] isMainThread]) {
        
        [_loadingView stopAnimating];
        [_loadingView removeFromSuperview];
        _loadingView = nil;
        @try {
            // 可能会出现崩溃的代码
            self.view.userInteractionEnabled = YES;
            
        }
        @catch (NSException *exception) {
            // 捕获到的异常exception
        }
        @finally {
            // 结果处理
        }
    }
    else{
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [_loadingView stopAnimating];
            [_loadingView removeFromSuperview];
            _loadingView = nil;
            @try {
                // 可能会出现崩溃的代码
                self.view.userInteractionEnabled = YES;
                
            }
            @catch (NSException *exception) {
                // 捕获到的异常exception
            }
            @finally {
                // 结果处理
            }
        });
    }
}



#pragma mark -
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
    self.sourceView.backgroundColor = [UIColor redColor];
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
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_removeLast)];
    [self.editorView addGestureRecognizer:tap];
    
}
- (void)setUpImagePicker {
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.allowsEditing = YES;
    self.selectedImageScale = kDefaultScale; //by default scale to half the size
    
}
- (void)createToolBarScroll {
    
    self.toolBarScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOOL_BAR_HEIGHT)];
    
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
    self.toolbarHolder.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
    
    if (_alwaysShowToolbar) {
        
        self.toolbarHolder.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
        
    } else {
        
        self.toolbarHolder.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 44);
    }
    
    self.toolbarHolder.autoresizingMask = self.toolbar.autoresizingMask;
    [self.toolbarHolder addSubview:self.toolBarScroll];
    [self.toolbarHolder insertSubview:backgroundToolbar atIndex:0];
    
}


#pragma mark -
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


#pragma mark -
#pragma mark - Toolbar Section
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
    
    float width = [UIScreen mainScreen].bounds.size.width / TOOL_ITEM_NUM;
    
    
    UIButton *voice = [UIButton buttonWithType:UIButtonTypeCustom];
    voice.frame = CGRectMake(width * 0, 0, width, 49);
    [voice setImage:[UIImage imageNamed:@"t1.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [voice setImage:[UIImage imageNamed:@"t1.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [voice addTarget:self action:@selector(_voice) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:voice];
    
    UIButton *recognition = [UIButton buttonWithType:UIButtonTypeCustom];
    recognition.frame = CGRectMake(width * 1, 0, width, 49);
    [recognition setImage:[UIImage imageNamed:@"textrecognition.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [recognition setImage:[UIImage imageNamed:@"textrecognition.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [recognition addTarget:self action:@selector(_recognition) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:recognition];
    
    UIButton *select = [UIButton buttonWithType:UIButtonTypeCustom];
    select.frame = CGRectMake(width * 2, 0, width, 49);
    [select setImage:[UIImage imageNamed:@"t2.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [select setImage:[UIImage imageNamed:@"t2.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [select addTarget:self action:@selector(_select) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:select];
    
    
    UIButton *textStyle = [UIButton buttonWithType:UIButtonTypeCustom];
    textStyle.frame = CGRectMake(width * 3, 0, width, 49);
    [textStyle setImage:[UIImage imageNamed:@"t3.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [textStyle setImage:[UIImage imageNamed:@"t3.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [textStyle addTarget:self action:@selector(_textStyle) forControlEvents:UIControlEventTouchUpInside];
    self.textStyleButton = textStyle;
    [self.toolbarView addSubview:textStyle];
    UIButton *size = [UIButton buttonWithType:UIButtonTypeCustom];
    size.frame = CGRectMake(width * 4, 0, width, 49);
    [size setImage:[UIImage imageNamed:@"t4.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [size setImage:[UIImage imageNamed:@"t4.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [size addTarget:self action:@selector(_textSize) forControlEvents:UIControlEventTouchUpInside];
    self.textSizeButton = size;
    [self.toolbarView addSubview:size];
    
    UIButton *alignment = [UIButton buttonWithType:UIButtonTypeCustom];
    alignment.frame = CGRectMake(width * 5, 0, width, 49);
    [alignment setImage:[UIImage imageNamed:@"t5.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [alignment setImage:[UIImage imageNamed:@"t5.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [alignment addTarget:self action:@selector(_textAlignment) forControlEvents:UIControlEventTouchUpInside];
    self.textAlignmentButton = alignment;
    [self.toolbarView addSubview:alignment];
    
    UIButton *color = [UIButton buttonWithType:UIButtonTypeCustom];
    color.frame = CGRectMake(width * 6, 0, width, 49);
    [color setImage:[UIImage imageNamed:@"t6.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [color setImage:[UIImage imageNamed:@"t6.png" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [color addTarget:self action:@selector(_textColor) forControlEvents:UIControlEventTouchUpInside];
    color.imageView.clipsToBounds = YES;
    color.imageView.layer.cornerRadius = 6.0f;
    self.textColorButton = color;
    [self.toolbarView addSubview:color];
    [self.toolBarScroll addSubview:self.toolbarView];
}


#pragma mark -
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


#pragma mark -
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
    if (_isActionStyle) {
        
        [self.textStyleButton setImage:[UIImage imageNamed:styleStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [self.textStyleButton setImage:[UIImage imageNamed:styleStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    }
    
    
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
    if (_isActionAlignment) {
        
        [self.textAlignmentButton setImage:[UIImage imageNamed:alignmentStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [self.textAlignmentButton setImage:[UIImage imageNamed:alignmentStr inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    }
    
    
    UIImage *image = [UIImage imageNamed:@"t6"];
    NSString *colorStr = @"";
    for (NSString *item in itemNames) {
        
        if ([item hasPrefix:@"#"]) {
            
            colorStr = [item stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
        }
    }
    
    if (colorStr.length > 0) {
        
        long colorLong = strtoul([colorStr cStringUsingEncoding:NSUTF8StringEncoding], 0, 16);
        
        UIColor *color = UIColorFromRGB(colorLong);
        image = [self createImageWithColor:color];
    }
    
    if (_isActionColor) {
        
        [self.textColorButton setImage:image forState:UIControlStateNormal];
        [self.textColorButton setImage:image forState:UIControlStateSelected];
    }
   
    
}



#pragma mark -
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


#pragma mark -
#pragma mark - UIWebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    
    NSString *text = [self getText];
    if (text.length > 5000) {
        
        [self alertMessage:@"文字内容过长,不超过5000字" delayFordisimissComplete:1];
        [self setHTML:self.lastHtmlString];
    }
    self.lastHtmlString = [self getHTML];
    
    NSString *urlString = [[request URL] absoluteString];
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    }
    else if ([urlString rangeOfString:@"callback://0/"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *className = [urlString stringByReplacingOccurrencesOfString:@"callback://0/" withString:@""];

        NSLog(@"%@", [self getHTML]);
        NSLog(@"%@", className);
        //if (self.lastHtmlString.length > 0) {
            
            [self updateToolViewWithButtonName:className];
        //}
        
    } else if ([urlString rangeOfString:@"debug://"].location != NSNotFound) {
        
        
        // We recieved the callback
        NSString *debug = [urlString stringByReplacingOccurrencesOfString:@"debug://" withString:@""];
        debug = [debug stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
        
    }
    else if ([urlString rangeOfString:@"scroll://"].location != NSNotFound) {
        
        NSInteger position = [[urlString stringByReplacingOccurrencesOfString:@"scroll://" withString:@""] integerValue];
        [self editorDidScrollWithPosition:position];
        
    }
    else if ([urlString rangeOfString:@"iOSTourWay.keyUp"].location != NSNotFound) {
        
        [self _removeLast];
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
            //[self focusTextEditor];
        });
    }
    
    /*
     
     Callback for when text is changed, solution posted by richardortiz84 https://github.com/nnhubbard/ZSSRichTextEditor/issues/5
     
     */
    JSContext *ctx = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    ctx[@"contentUpdateCallback"] = ^(JSValue *msg) {
        

        if (_receiveEditorDidChangeEvents) {
            
            [self editorDidChangeWithText:[self getText] andHTML:[self getHTML]];
            
        }
        
        [self checkForMentionOrHashtagInText:[self getText]];
        
    };
    [ctx evaluateScript:@"document.getElementById('zss_editor_content').addEventListener('input', contentUpdateCallback, false);"];
    
    JSContext  *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    ;
    context[@"native"] = self;
    context[@"resultParams"] =
    ^(NSString *jsonStr)
    {
        
        [self _removeLast];
    };
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
- (void)editorDidScrollWithPosition:(NSInteger)position {
    
}
//Blank implementation
- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html  {
    
}
//Blank implementation
- (void)hashtagRecognizedWithWord:(NSString *)word {
    
}
//Blank implementation
- (void)mentionRecognizedWithWord:(NSString *)word {
    
}


#pragma mark -
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


#pragma mark -
#pragma mark - Asset Picker
- (void)showInsertURLAlternatePicker {
    // Blank method. User should implement this in their subclass
}
- (void)showInsertImageAlternatePicker {
    // Blank method. User should implement this in their subclass
}


#pragma mark -
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


#pragma mark -
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


#pragma mark -
#pragma mark - canPerformAction
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    
    NSString *temp = [UIPasteboard generalPasteboard].string;
    if (![temp isEqualToString:self.pasteBoardText] && temp.length > 0) {
        
        self.pasteBoardText = temp;
        [UIPasteboard generalPasteboard].string = self.pasteBoardText;
        
    }
    //self.pasteBoardText = [UIPasteboard generalPasteboard].string;
    return [super canPerformAction:action withSender:sender];
}



#pragma mark -
#pragma mark - IFlySpeechRecognizerDelegate
/**
 音量回调函数
 volume 0－30
 ****/
- (void) onVolumeChanged: (int)volume{
    if (self.isCanceled) {
        //        [self.popView removeFromSuperview];
        return;
    }
    
    __block NSInteger index = 0;
    
    NSInteger height = 3 + 27.0 /  30 * volume;
    [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        float origalY = (TOOL_BAR_HEIGHT - height - 6) / 2.0;
        
        float doneButtonWidth = 59;
        
        float width = (SCREEN_SIZE.width - doneButtonWidth) / 2.0 - 6 - 30;
        
        NSInteger count = ceilf(width / (3.0 + 6.0));
        
        NSArray *subviews = self.voiceView.subviews;
        for (int i = 0; i < count; i ++ ) {
            
            for (UIView *view in subviews) {
                if (view.tag == (100 + index)) {
                    
                    [UIView animateWithDuration:0.05 animations:^{
                        
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
    
    
}
/**
 开始识别回调
 ****/
- (void) onBeginOfSpeech{

    
    if (self.isStreamRec == NO){
        
        self.isBeginOfSpeech = YES;
    }
}
/**
 停止录音回调
 ****/
- (void) onEndOfSpeech{
    
    self.isRecording = NO;
    [_pcmRecorder stop];
    [self.voiceView removeFromSuperview];
}
/**
 听写结束回调（注：无论听写是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error{
    
    if ([IATConfig sharedInstance].haveView == NO ) {
        
        NSString *text ;
        
        if (self.isCanceled) {
            text = @"识别取消";
            
        } else if (error.errorCode == 0 ) {
            if (_result.length == 0) {
                text = @"无识别结果";
            }else {
                text = @"";
                //清空识别结果
                _result = nil;
            }
        }else {
            text = [NSString stringWithFormat:@"发生错误：%d %@", error.errorCode,error.errorDesc];
        }
        
        if (text.length > 0) {
            //[self alertMessage:text delayFordisimissComplete:1.0f];
        }
    }
    else {
        //[self alertMessage:@"识别结束" delayFordisimissComplete:1.0f];
    }
    self.isRecording = NO;
}
/**
 无界面，听写结果回调
 results：听写结果
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast{
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
    [self insertHTML:resultFromJson];
    self.isRecording = NO;
}
/**
 有界面，听写结果回调
 resultArray：听写结果
 isLast：表示最后一次
 ****/
- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast{
    
    self.isRecording = NO;
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
    }
    //_textView.text = [NSString stringWithFormat:@"%@%@",_textView.text,result];
}
/**
 听写取消回调
 ****/
- (void) onCancel{
    
    self.isRecording = NO;
}


#pragma mark -
#pragma mark - AipOcrResultDelegate
- (void)ocrOnGeneralImageResult:(id)resut {

    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"true"};
    
    [self startLoading];
    [[AipOcrService shardService] detectTextFromImage:(UIImage *)resut withOptions:options successHandler:^(id result) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self stopLoading];
            NSMutableString *message = [NSMutableString string];
            if(result[@"words_result"]){
                
                for(NSDictionary *obj in result[@"words_result"]){
                    
                    [message appendFormat:@"%@", obj[@"words"]];
                }
            }
            else{
                [message appendFormat:@"%@", result];
            }
            
            [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.restorerange()"];
            
            if (message.length == 0) {
                
                [self alertMessage:@"无法检测到文字" delayFordisimissComplete:2];
            }
            else{
                
                [self insertHTML:message];
                
            }
        });
        
    } failHandler:^(NSError *err) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{

            [self stopLoading];
            [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.restorerange()"];
        [self alertMessage:@"无法检测到文字" delayFordisimissComplete:2];
        });
    }];
}





@end




