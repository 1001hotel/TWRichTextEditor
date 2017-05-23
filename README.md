# TWRichTextEditor
富文本编辑器可以手动输入、粘贴输入、通过语音输入、通过OCR扫描等方式输入文字。从而可以改变文字的样式、大小、对齐方式、颜色等信息。

语音输入：
用的是讯飞输入语音识别

需要在appDelegate.m中下面的方法配置
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

//设置sdk的log等级，log保存在下面设置的工作路径中
[IFlySetting setLogFile:LVL_ALL];

//打开输出在console的log开关
[IFlySetting showLogcat:YES];

//设置sdk的工作路径
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
NSString *cachePath = [paths objectAtIndex:0];
[IFlySetting setLogFilePath:cachePath];

//创建语音配置,appid必须要传入，仅执行一次则可
NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",@"58809cff"];

//所有服务启动前，需要确保执行createUtility
[IFlySpeechUtility createUtility:initString];

}



文字OCR扫描：
用的是百度的OCR扫描方式
支持的系统和硬件版本

iOS: 8.0 以上
架构：i386 x86_64 armv7 armv7s arm64
因为在AipBase.framework中包含有i386 x86_64架构的东西，在提交App Store的时候需要把这个先移除才能提交，否则就提交不上去
去除的方法

查看包含的架构信息
lipo -info /Users/luomeng/Desktop/AipBase.framework/AipBase

拆分armv7s
lipo AipBase.framework/AipBase -thin armv7s -output AipBase.framework/AipBase-armv7s

拆分armv7
lipo AipBase.framework/AipBase -thin armv7 -output AipBase.framework/AipBase-armv7

拆分armv64
lipo AipBase.framework/AipBase -thin armv64 -output AipBase.framework/AipBase-armv64

合并
lipo -create AipBase.framework/AipBase-armv7 AipBase.framework/AipBase-arm64 AipBase.framework/AipBase-armv7s -output AipBase.framework/AipBase



framework的BundleId必须和项目BundleId统一，否则不能正常操作

不需要在appDelegate.m中配置，已经封装好了





