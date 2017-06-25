#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'json'

module Y0shin0
  class Event
    attr_reader :event_name, :event_data

    def initialize(event_name, event_data)
      @event_name = event_name
      @event_data = event_data
    end

    def json
      { event_name: @event_name, event_data: @event_data.json }.to_json
    end

    def from_json(json)
      ev = JSON.parse(json, symbolize_names: true)
      Event.new(ev[:event_name], EventData.from_json(ev[:event_data]))
    end

    def to_s
      json
    end

    def to_str
      to_s
    end
  end
end