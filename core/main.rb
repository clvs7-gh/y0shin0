#!/usr/bin/env ruby 
# -*- coding: utf-8 -*-
include Pluggaloid

# Load config first
Dir.glob(File.join(__dir__, 'config', '**', '*.rb')) do |config|
  require_relative config
end
# Initialize logger
require_relative File.join(__dir__, 'logger')
Y0shin0::Logger.new('Y0shin0_Ruby').info("Version #{Y0shin0::VERSION} started!")
# Load all remaining core components
Dir.glob(File.join(__dir__, '**', '*.rb')) do |comp|
  require_relative comp
end

# Start plugins
Dir.glob(File.join(ROOT_DIR, 'plugins', '*', 'plugin.main.rb')) do |plugin|
  require_relative plugin
end

begin
  loop do
    Delayer.run
    sleep 0.01
  end
rescue Interrupt
  Plugin.instances.each { |i| i.finalize if i.methods.include? 'finalize' }
  Plugin[:nfc].stop_fork if Y0shin0::CoreConfig.is_plugin_active :nfc
end