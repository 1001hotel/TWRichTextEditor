
Pod::Spec.new do |s|

  s.name         = "TWRichTextEditor"
  s.version      = "0.1.5"
  s.summary      = "A rich text editor used on iOS."
  s.description  = <<-DESC
                   It is a rich text editor used on iOS, which implement by Objective-C.
                   DESC
  s.homepage     = "https://github.com/1001hotel/TWRichTextEditor"
  s.license      = "MIT"
  s.author             = { "xurenyan" => "812610313@qq.com" }
  s.platform     = :ios, "5.0"
  s.requires_arc = true
  s.source       = { :git => "https://github.com/1001hotel/TWRichTextEditor.git", :tag => s.version.to_s }
  s.source_files  = "TWRichTextEditor/**/*.{h,m,pch,plist}"
  "vendored_frameworks": "TWRichTextEditor/**/*.framework}",

  #s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"


 
  # s.resource  = "icon.png"
   s.resources = "TWRichTextEditor/**/*.png", "TWRichTextEditor/**/ZSSRichTextEditor.js", "TWRichTextEditor/**/editor.html", "TWRichTextEditor/**/jQuery.js", "TWRichTextEditor/**/JSBeautifier.js"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


 
  # s.frameworks = "iflyMSC", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
