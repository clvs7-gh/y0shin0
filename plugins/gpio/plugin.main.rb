#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rpi_gpio' if Y0shin0::CoreConfig.is_plugin_active :gpio

Plugin.create :gpio do
  next unless Y0shin0::CoreConfig.is_plugin_active :gpio

  @log = Y0shin0::Logger.new('GPIO Plugin')

  class GPIOItem
    attr_reader :pin_num, :initial_value, :as, :last_value

    def initialize(pin_num, initial_value = :low, as = :output)
      @pin_num = pin_num
      @initial_value = initial_value
      @as = as
      @last_value = nil
      RPi::GPIO.setup(pin_num, initialize: initial_value, as: as)
    end

    def enable
      RPi::GPIO.set_high @pin_num
    end

    def disable
      RPi::GPIO.set_low @pin_num
    end

    def log
      @last_value = RPi::GPIO.high? @pin_num
    end

    def reverse
      RPi::GPIO.high?(@pin_num) ? disable : enable
    end

    def changed?
      @last_value != enable?
    end

    def enable?(is_log = false)
      (log if is_log) || (RPi::GPIO.high? @pin_num)
    end
  end

  def finalize
    cleanup
  end

  def cleanup
    RPi::GPIO.clean_up
  end

  Thread.new {
    # Set numbers
    RPi::GPIO.set_numbering :board
    @eyes = {
      left: (GPIOItem.new(Y0shin0::CoreConfig[:gpio][:pins][:led_eye_left], :high)),
      right: (GPIOItem.new(Y0shin0::CoreConfig[:gpio][:pins][:led_eye_right], :high)),
    }
    @eyes_sub = {}
    @use_sub = false
    if !Y0shin0::CoreConfig[:gpio][:pins][:led_eye_left_sub].nil? && !Y0shin0::CoreConfig[:gpio][:pins][:led_eye_right_sub].nil?
      @eyes_sub[:left] = GPIOItem.new(Y0shin0::CoreConfig[:gpio][:pins][:led_eye_left_sub])
      @eyes_sub[:right] = GPIOItem.new(Y0shin0::CoreConfig[:gpio][:pins][:led_eye_right_sub])
      @use_sub = true
    end
    @others = []
    Y0shin0::CoreConfig[:gpio][:pins][:led_others].each { |n| @others.push(GPIOItem.new(n, :high)) }
    @battery_low = GPIOItem.new(Y0shin0::CoreConfig[:gpio][:pins][:led_battery_low])
    @vibrator = GPIOItem.new(Y0shin0::CoreConfig[:gpio][:pins][:vibrator])

    ##### Functions for GPIO operation #####

    def read_all
      @eyes.each_value(&:log)
      @eyes_sub.each_value(&:log)
      @others.each(&:log)
      @vibrator.log
    end

    def up_all(without_eyes = false)
      @eyes.each_value(&:enable) unless without_eyes
      @eyes_sub.each_value(&:enable) unless without_eyes
      @others.each(&:enable)
      @vibrator.enable
    end

    def up_last(without_eyes = false)
      @eyes.each_value { |i| i.enable if i.last_value } unless without_eyes
      @eyes_sub.each_value { |i| i.enable if i.last_value } unless without_eyes
      @others.each { |i| i.enable if i.last_value }
      @vibrator.enable if @vibrator.last_value
    end

    def up_changed(without_eyes = false)
      @eyes.each_value { |i| i.enable if i.changed? } unless without_eyes
      @eyes_sub.each_value { |i| i.enable if i.changed? } unless without_eyes
      @others.each { |i| i.enable if i.changed? }
      @vibrator.enable if @vibrator.changed?
    end

    def down_all(without_eyes = false)
      @eyes.each_value(&:disable) unless without_eyes
      @eyes_sub.each_value(&:disable) unless without_eyes
      @others.each(&:disable)
      @vibrator.disable
    end

    def blink(time = 0.5, is_eye_only = false)
      read_all
      down_all true unless is_eye_only
      reverse_eyes
      sleep time
      reverse_eyes
      up_last true unless is_eye_only
      sleep time
    end

    def reverse_eyes
      [@eyes, @eyes_sub].each { |a| a.each_value(&:reverse) }
    end

    def change_eye_mode(mode)
      if mode == 1
        @eyes.each_value(&:enable)
        @eyes_sub.each_value(&:disable)
      else
        @eyes.each_value(&:disable)
        @eyes_sub.each_value(&:enable)
      end
    end


    ##### MAIN #####

    on_event_client do |y_event|
      case y_event.event_name
        when 'system'
          case y_event.event_data.type
            when 'mode_changed'
              mode = y_event.event_data.mode
              @log.info("Mode changed : #{mode}")
              sleep 0.3
              change_eye_mode(mode) if @use_sub
              @vibrator.enable
              sleep 0.3
              5.times do
                blink 0.2
              end
              @vibrator.disable
          end
        when 'nfc'
          @log.info("Scan completed (uid : #{y_event.event_data.value})")
          @vibrator.enable
          3.times { blink 0.125, true }
          @vibrator.disable
        when 'battery'
          if y_event.event_data.type == 'level_low'
            @log.warn("Battery level is low (#{y_event.event_data.value})!")
            @battery_low.enable
          end
      end
    end

  }.trap { |e|
    @log.error('Unrecovable error has been occurred while communicating with GPIO : ' + e.inspect)
    finalize
  }
end
