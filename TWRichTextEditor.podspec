
Pod::Spec.new do |s|

  s.name         = "TWRichTextEditor"
  s.version      = "1.1.9"
  s.summary      = "A rich text editor used on iOS."
  s.description  = <<-DESC
                   It is a rich text editor used on iOS, which implement by Objective-C.
                   DESC
  s.homepage     = "https://github.com/1001hotel/TWRichTextEditor"
  s.license      = "MIT"
  s.author             = { "xurenyan" => "812610313@qq.com" }
  s.platform     = :ios, "8.0"
  s.requires_arc = true
  s.source       = { :git => "https://github.com/1001hotel/TWRichTextEditor.git", :tag => s.version.to_s }
  s.source_files  = "TWRichTextEditor/**/*.{h,m}"
  s.vendored_frameworks = "TWRichTextEditor/ThirdParty/iflyMSC.framework", "TWRichTextEditor/ThirdParty/AipBase.framework", "TWRichTextEditor/ThirdParty/AipOcrSdk.framework"
 #s.vendored_libraries = '/Pod/Classes/*.a'
 s.resources = "TWRichTextEditor/**/*.png", "TWRichTextEditor/**/ZSSRichTextEditor.js", "TWRichTextEditor/**/editor.html", "TWRichTextEditor/**/jQuery.js", "TWRichTextEditor/**/JSBeautifier.js"
 s.frameworks = "AVFoundation", "SystemConfiguration", "Foundation", "CoreTelephony", "AudioToolbox", "UIKit", "CoreLocation", "Contacts", "AddressBook", "QuartzCore", "CoreGraphics"
 s.libraries = "z", "c++"
 s.dependency "TWFreshLoadingView", "~> 0.8.0"
 s.dependency "TWCommonMoudle", "~> 1.4.0"

end
