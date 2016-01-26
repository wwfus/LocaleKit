Pod::Spec.new do |s|
  s.name             = "LocaleKit"
  s.version          = "0.1.0"
  s.summary          = "A short description of LocaleKit."

s.description      = <<-DESC
DESC

s.homepage         = "https://github.com/<GITHUB_USERNAME>/LocaleKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Nick Lee" => "nick@tendigi.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/LocaleKit.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/**/*.swift'

  s.dependency 'Zip', '~> 0.1'

end
