Pod::Spec.new do |s|

  s.name         = "THRNetwork"
  s.version      = "0.2.0"
  s.summary      = "A collection of classes to aid performing network operations."
  s.homepage     = "https://gitlab.3squared.com/samoakley/Network"
  s.license      = { :type => 'Custom', :file => 'LICENCE' }
  s.author             = { "Sam Oakley" => "sam.oakley@3squared.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "git@gitlab.3squared.com:iOSLibraries/THRNetwork.git", :tag => s.version.to_s }
  s.source_files = "Network", "Network/**/*.{h,m,swift}"
	s.dependency 'THROperations', '~> 0.1.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3' }

end
