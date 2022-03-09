#
# Be sure to run `pod lib lint DDSwiftRuntime.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name     = 'DDSwiftRuntime'
  s.version  = '0.0.3'
  s.license  = 'MIT'
  s.summary  = 'A description of DDSwiftRuntime.'
  s.homepage = 'https://github.com/dondong/DDSwiftRuntime'
  s.authors  = { 'dondong' => 'the-last-choice@qq.com' }
  s.source   = { :git => 'https://github.com/dondong/DDSwiftRuntime.git', :tag => s.version  }
  s.module_name   = 'DDSwiftRuntime'
  s.swift_version = '5.5'
  
  s.platform = :ios
  s.ios.deployment_target = '11.0'


  s.ios.pod_target_xcconfig = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.dd.kit.swift.runtime' }

  s.source_files = 'Framework/*'
  
end
