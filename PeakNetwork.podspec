Pod::Spec.new do |s|

  s.name         = "PeakNetwork"
  s.version      = "4.1.1"
  s.summary      = "A collection of classes to aid performing network operations."
  s.homepage     = "https://github.com/3squared/PeakNetwork"
  s.license      = { :type => 'Custom', :file => 'LICENSE.md' }
  s.author       = { "Sam Oakley" => "sam.oakley@3squared.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/3squared/PeakNetwork.git", :tag => s.version.to_s }
  s.source_files = "PeakNetwork", "PeakNetwork/**/*.{h,m,swift}"
  s.dependency 'PeakOperation'
  s.swift_version = '4.2'

end
