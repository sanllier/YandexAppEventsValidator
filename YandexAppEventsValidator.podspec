Pod::Spec.new do |s|

  s.homepage     = "https://github.com/sanllier/YandexAppEventsValidator"
  s.summary      = "YandexAppEventsValidator"

  s.name         = "YandexAppEventsValidator"
  s.version      = "0.1"
  s.license      = "MIT"
  s.author       = { "Alexander Goremykin" => "sanllier@yandex-team.ru" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/sanllier/YandexAppEventsValidator.git", :tag => "#{s.version}" }

  s.source_files  = "YandexAppEventsValidator/**/*.{swift,h,m}"

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3' }

end
