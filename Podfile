platform :ios, '10.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'git@gitlab.3squared.com:iOSLibraries/CocoaPodSpecs.git'

target 'PeakNetwork' do
	use_frameworks!

	pod 'PeakOperation', :path => '../PeakOperation'
			
	target 'PeakNetworkTests' do
		inherit! :search_paths
	end
end
