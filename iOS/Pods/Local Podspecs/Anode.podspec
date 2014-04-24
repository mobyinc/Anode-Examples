Pod::Spec.new do |s|
  s.name             = "Anode"
  s.version          = "1.0.0"
  s.summary          = "Moby Anode library for data access and server communication."
  s.description      = <<-DESC
                       Moby Anode library for data access and server communication.
                       DESC
  s.homepage         = "http://builtbymoby.com/"
  s.screenshots      = 
  s.license          = 'All rights reserved.'
  s.author           = { "mobyjames" => "james@builtbymoby.com" }
  s.source           = { :git => "https://github.com/mobyjames/Anode.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Anode/**/*.{h,m}'

  s.public_header_files = 'Anode/*.h'
end
