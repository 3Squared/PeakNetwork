Pod::Spec.new do |s|

  s.name         = "PeakNetwork"
  s.version      = "4.1.0"
  s.summary      = "A collection of classes to aid performing network operations."
  s.homepage     = "https://gitlab.3squared.com/MobileTeam/PeakNetwork"
  s.license      = { :type => 'Custom', :file => 'LICENSE.md' }
  s.author       = { "Sam Oakley" => "sam.oakley@3squared.com" }
  s.platform     = :ios, "10.0"
  s.source       = { :git => "git@gitlab.3squared.com:MobileTeam/PeakNetwork.git", :tag => s.version.to_s }
  s.source_files = "PeakNetwork", "PeakNetwork/**/*.{h,m,swift}"
  s.dependency 'PeakOperation'
  s.swift_version = '4.2'

end
