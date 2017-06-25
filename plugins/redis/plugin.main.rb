#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'redis'
require 'json'

Plugin.create :redis do
  next unless Y0shin0::CoreConfig.is_plugin_active :redis

  @log = Y0shin0::Logger.new('Redis Plugin')

  Thread.new {
    pub = Redis.new(Y0shin0::CoreConfig[:redis])
    sub = Redis.new(Y0shin0::CoreConfig[:redis])

    on_event_client do |y_event|
      begin
        pub.publish('client_events', y_event)
      rescue Redis::CannotConnectError => e
        @log.error('Publish error!' + e.inspect)
        exit 1
      end
    end

    begin
      @log.info('Subscribing...')
      sub.subscribe('server_events') do |on|
        on.message do |_, message|
          @log.info('Got event from server.')
          Plugin.call(:event_server, JSON.parse(message, { symbolize_names: true }))
        end
      end
    rescue Redis::CannotConnectError => e
      @log.error('Subscribe error! Exception : ' + e.inspect)
      exit 1
    rescue StandardError => e
      @log.warn('Failed to parse event message : ' + e.inspect)
      retry
    end
  }.trap { |e|
    @log.error('Unrecovable error has been occurred while subscribing event : ' + e.inspect)
  }
end
