#
# Be sure to run `pod lib lint BlazeSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'BlazeIMA'
    s.version          = '1.11.4'
    s.summary          = 'BlazeIMA allows IMA in inApp Stories and more'

    s.description      = <<-DESC
    TODO: Add long description of the pod here.
                       DESC

    s.homepage         = 'https://wsc-sports.com'
    s.license          = { :type => 'Closed Source'}
    s.author           = { 'Mobile Dev WSC' => 'developers@wsc-sports.com' }
    s.source = {
        :git => 'https://github.com/WSCSports/blaze-specs-ios.git',
        :tag => "#{s.version}"
      }

    s.ios.deployment_target = '13.0'
    s.swift_version = '5.3'
    s.source_files = 'Sources/BlazeIMA/**/*.{h,m,mm,swift}'
    s.dependency 'GoogleAds-IMA-iOS-SDK', '>= 3.18.4', '< 4.0.0'
    
    s.dependency 'BlazeSDK', "= #{s.version}"

    s.static_framework = true
end
