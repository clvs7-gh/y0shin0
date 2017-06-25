#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

Plugin.create :twintail do
  next unless Y0shin0::CoreConfig.is_plugin_active :twintail

  Thread.new do
    loop do
      Plugin.call(
        :event_client,
        Y0shin0::Event.new(
          'nfc',
          Y0shin0::EventData.new('card', '00112233')
        )
      )
      puts 'Twintail!'
      sleep 5
      Plugin.call(
        :event_client,
        Y0shin0::Event.new(
          'nfc',
          Y0shin0::EventData.new('card', 'aabbccdd')
        )
      )
      sleep 5
      Plugin.call(
        :event_client,
        Y0shin0::Event.new(
          'system',
          Y0shin0::EventData.new('mode_changed', '44556677')
        )
      )
      Y0shin0::State.change
      sleep 5
    end
  end.trap { |e| p e }
end
