#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

Plugin.create :battery do
  next unless Y0shin0::CoreConfig.is_plugin_active :battery

  @log = Y0shin0::Logger.new('Battery Plugin v2')

  # Check i2cget
  `which i2cget > /dev/null 2>&1`
  raise 'i2cget is required! Please activate I2C and install i2c-tools!' if $? != 0

  Thread.new {
    def read
      # Initialize sensor : 0b10001000 => 0x88
      # 7bit: Whether to convert
      # 5-6bit: (Un used)
      # 4bit: Continuous conversion
      # 2-3bit: Accuracy
      # 0-1 bit: Magnification

      # read 16bits
      hex_str = `i2cget -y 1 #{Y0shin0::CoreConfig[:battery][:address]} #{Y0shin0::CoreConfig[:battery][:sensor_value_write]} w`.strip
      # digit = gb*256 + lb
      # -32767 <= digit <= 32767  <=>  -2048 mV <= v <= 2048 mV
      # partial pressure -> actual voltage
      (hex_str[-2, 2].hex.to_f * 256 + hex_str[-4, 2].hex.to_f) * 2048 / 32767 * 4
    end

    loop do
      begin
        level = read.round(1)
        @log.info('Battery level : ' + level.to_s + ' mV')
        # If battery level is low, make the battery_low event.
        if level > Y0shin0::CoreConfig[:battery][:low_threshold]
          Plugin.call(:client_event, Y0shin0::Event.new(
            'battery',
            Y0shin0::EventData.new('level_normal', level)
          ))
        else
          Plugin.call(:client_event, Y0shin0::Event.new(
            'battery',
            Y0shin0::EventData.new('level_low', level)
          ))
        end
      rescue StandardError => e
        @log.warn('Can\'t read battery status : ' + e.inspect)
      end
      sleep(30)
    end
  }.trap { |e|
    @log.error('Unrecovable error has been occurred while reading battery status : ' + e.inspect)
  }
end

