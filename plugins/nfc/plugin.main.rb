#!/usr/bin/env ruby 
# -*- coding: utf-8 -*-
require 'nfc'
require 'time'
require 'timeout'

Plugin.create :nfc do
  next unless Y0shin0::CoreConfig.is_plugin_active :nfc

  @log = Y0shin0::Logger.new('NFC Plugin')
  @pid = nil

  def finalize
    stop_fork
  end

  def stop_fork
    Process.kill(9, @pid) unless @pid.nil?
  end

  Thread.new {
    loop do
      r, w = IO.pipe

      @pid = fork do
        r.close
        retried = 0

        begin
          # noinspection RubyArgCount
          ctx = NFC::Context.new
          dev = ctx.open nil
          uid = dev.select.uid
          w.write uid.map { |i| "0#{i.to_s(16)}"[-2, 2] }.join
        rescue
          if retried < Y0shin0::CoreConfig[:nfc][:max_try]
            @log.warn("NFC Device Error. Retrying (challenge #{retried}).")
            retried += 1
            sleep 0.3
            retry
          end
          w.close
          exit 1
        end
      end
      w.close
      # Mitigate device lock issue
      begin
        timeout Y0shin0::CoreConfig[:nfc][:timeout] || 30 do
          Process.waitpid @pid
        end
      rescue TimeoutError
        stop_fork
        r.close
        next
      end

      if $? != 0
        @log.error('NFC reader error!')
        exit 1
      end

      uid = r.read.downcase
      r.close
      if uid != Y0shin0::CoreConfig[:main][:soul_card][:uid]
        Plugin.call(:event_client, Y0shin0::Event.new(
          'nfc',
          Y0shin0::EventData.new('card', uid, Y0shin0::State[:mode])
        ))
      else
        new_mode = Y0shin0::State.change
        Plugin.call(:event_client, Y0shin0::Event.new(
          'system',
          Y0shin0::EventData.new('mode_changed', uid, new_mode)
        ))
      end

      sleep 0.5
    end
  }.trap { |e|
    @log.error('Unrecovable error has been occurred while communicating with NFC : ' + e.inspect)
    finalize
  }
end
