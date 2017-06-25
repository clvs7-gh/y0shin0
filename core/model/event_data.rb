#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'json'
require 'time'

module Y0shin0
  class EventData
    attr_reader :type, :value, :mode, :timestamp

    def initialize(type, value, mode = nil, timestamp = Time.now.to_i)
      @type = type
      @value = value
      @mode = mode
      @timestamp = timestamp
    end

    def json
      { type: @type, value: @value, mode: @mode, timestamp: @timestamp }.to_json
    end

    def from_json(json)
      ev = JSON.parse(json, symbolize_names: true)
      EventData.new(ev[:type], ev[:value], ev[:mode], ev[:timestamp])
    end

    def to_s
      json
    end

    def to_str
      to_s
    end
  end
end