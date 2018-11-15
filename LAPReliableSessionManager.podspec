#
#  Be sure to run `pod spec lint pieces.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name               = "LAPReliableSessionManager"
  s.version            = "0.1.1"
  s.summary            = "Send data packages in a reliable way, with guaranteed delivery"
  s.description        = "If you want to send data packages to a web service in a reliable way, with guaranteed delivery."
  s.homepage           = "https://github.com/layered-pieces/LAPReliableSessionManager"
  s.license            = "MIT"
  s.author             = { "Oliver Letterer" => "oliver.letterer@gmail.com" }
  s.social_media_url   = "https://twitter.com/OliverLetterer"
  s.source             = { :git => "https://github.com/layered-pieces/LAPReliableSessionManager.git", :tag => "#{s.version}" }
  s.requires_arc       = true
  s.platforms          = { :ios => '9.0', :tvos => '9.0', :watchos => '2.0' }

  s.source_files = 'LAPReliableSessionManager'

  s.dependency "AFNetworking", "~> 3.0"
  s.dependency "LAPWebServiceReachabilityManager", "~> 0.1"
end
