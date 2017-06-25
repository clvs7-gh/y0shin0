#!/usr/bin/env ruby 
# -*- coding: utf-8 -*-

module Y0shin0
  module State
    # Initialize state
    @state = {
      mode: 1
    }

    def self.change
      @state[:mode] = @state[:mode] == 1 ? 2 : 1
    end

    def self.[](key)
      @state[key]
    end

    def self.[]=(key, value)
      @state[key] = value
    end
  end
end