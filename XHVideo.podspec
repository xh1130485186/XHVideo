Pod::Spec.new do |spec|


  spec.name         = "XHVideo"
  spec.version      = "0.0.1"
  spec.summary      = "XHVideo，视频播放或者录制。"
  
  spec.description  = <<-DESC
                    XHVideo是一个视频处理框架，对系统视频播放进行组装，播放调用更加简单，录制更加方便。
                   DESC

  spec.homepage     = "https://github.com/xh1130485186/XHVideo.git"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "xianghong" => "1130485186@qq.com" }

  spec.platform     = :ios, "8.0"

  spec.source       = { :git => "https://github.com/xh1130485186/XHVideo.git", :tag => spec.version }

  spec.resource  = "XHVideo/xh.video.bundle"

  spec.requires_arc = true
  
  spec.source_files = 'XHVideo/*.{h,m}'

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  spec.dependency "XHLoading"

end

