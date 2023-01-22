# platform :ios, '9.0'

target 'ScalePlayer' do
  use_frameworks!
  inhibit_all_warnings!

  pod 'MusicTheorySwift'
  pod 'CombineCocoa'
  pod 'Factory'
  pod 'TinyConstraints'
  pod 'SwiftLint'
  pod 'Peek', :configurations => ['Debug']
  
  target 'ScalePlayerTests' do
    inherit! :search_paths
    use_frameworks!
    pod 'MockingbirdFramework'
  end
end

