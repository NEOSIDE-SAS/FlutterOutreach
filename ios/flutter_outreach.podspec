#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_outreach.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_outreach'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for sending text and medias to many channels like Whatsapp / Line ...'
  s.description      = <<-DESC
Flutter plugin for sending text and medias to many channels like Whatsapp / Line ...
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Balink LTD' => 'yankelm@balink.net' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Alamofire'
  s.platform = :ios, '9.0'
  s.resources = 'Assets/*.jpg'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
