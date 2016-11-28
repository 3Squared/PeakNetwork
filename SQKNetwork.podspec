#
#  Be sure to run `pod spec lint Result.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "SQKNetwork"
  s.version      = "0.0.1"
  s.summary      = "A collection of classes to aid performing network operations."
  s.homepage     = "https://gitlab.3squared.com/samoakley/Network"
  s.license      = { :type => 'Custom', :file => 'LICENCE' }
  s.author             = { "Sam Oakley" => "sam.oakley@3squared.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "git@gitlab.3squared.com:samoakley/Network.git", :tag => s.version.to_s }
  s.source_files = "Network", "Network/**/*.{h,m,swift}"
	s.dependency 'SQKResult', '~> 0.0.1'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3' }

end
