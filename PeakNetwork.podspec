Pod::Spec.new do |s|

  s.name         = "PeakNetwork"
  s.version      = "3.1.2"
  s.summary      = "A collection of classes to aid performing network operations."
  s.homepage     = "https://gitlab.3squared.com/iOSLibraries/PeakNetwork"
  s.license      = { :type => 'Custom', :file => 'LICENCE' }
  s.author             = { "Sam Oakley" => "sam.oakley@3squared.com" }
  s.platform     = :ios, "10.0"
  s.source       = { :git => "git@gitlab.3squared.com:iOSLibraries/PeakNetwork.git", :tag => s.version.to_s }
  s.source_files = "PeakNetwork", "PeakNetwork/**/*.{h,m,swift}"
	s.dependency 'PeakOperations'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4' }

end
