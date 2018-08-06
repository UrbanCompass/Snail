Pod::Spec.new do |s|
  s.name         = "Snail"
  s.version      = "0.2.3"
  s.summary      = "An observables framework for Swift"
  s.homepage     = "https://github.com/UrbanCompass/Snail"
  s.license      = "MIT"
  s.author       = "Compass"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/UrbanCompass/Snail.git", :tag => "#{s.version}" }
  s.source_files  = "Snail/**/*.swift"
  s.swift_version = '4.0'
end
