#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

ROOT_DIR = __dir__
module Y0shin0
  VERSION = '0.101'

  begin
    require 'bundler/setup'
    Bundler.require(:default, :plugins)
  rescue
    STDERR.puts('Error while executing bundler!')
    exit 1
  end

  Delayer.default = Delayer.generate_class(priority: %i<high normal low>, default: :normal)
  # Run main
  require_relative File.join('core', 'main')
end