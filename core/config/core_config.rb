#!/usr/bin/env ruby 
# -*- coding: utf-8 -*-
require 'yaml'
require 'hashie'

module Y0shin0
  module CoreConfig
    # noinspection RubyArgCount
    @settings = Hashie::Mash.new(YAML.load_file(File.join(ROOT_DIR, 'config.yml')))

    def self.is_plugin_active(plugin)
      (!@settings[plugin].nil? && @settings[plugin][:active]) || false
    end

    def self.[](key)
      @settings[key]
    end
  end
end