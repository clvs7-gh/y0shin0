source 'https://rubygems.org'

group :default do
  gem 'pluggaloid', '>= 1.1.1', '< 2.0'
  gem 'delayer-deferred', '>= 1.1.1', '< 2.0'
  gem 'hashie', '>= 3.5.5', '< 4.0'
end

group :plugin do
  Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'plugins', '*', 'Gemfile'))){ |path|
    eval_gemfile path
  }
end
