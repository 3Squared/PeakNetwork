Pod::Spec.new do |s|

  s.name         = "THRNetwork"
  s.version      = "0.2.1"
  s.summary      = "A collection of classes to aid performing network operations."
  s.homepage     = "https://gitlab.3squared.com/iOSLibraries/THRNetwork"
  s.license      = { :type => 'Custom', :file => 'LICENCE' }
  s.author             = { "Sam Oakley" => "sam.oakley@3squared.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "git@gitlab.3squared.com:iOSLibraries/THRNetwork.git", :tag => s.version.to_s }
  s.source_files = "THRNetwork", "THRNetwork/**/*.{h,m,swift}"
	s.dependency 'THROperations'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4' }

end
