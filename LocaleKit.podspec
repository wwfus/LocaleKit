Pod::Spec.new do |s|
  s.name             = "LocaleKit"
  s.version          = "0.1.0"
  s.summary          = "LocaleKit makes it easy to manage "
  s.homepage         = "https://github.com/<GITHUB_USERNAME>/LocaleKit"
  s.license          = 'MIT'
  s.author           = { "Nick Lee" => "nick@tendigi.com" }
  s.source           = { :git => "https://github.com/TENDIGI/LocaleKit.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'Pod/**/*.swift'
  s.dependency 'zipzap', '~> 8.1'
end
