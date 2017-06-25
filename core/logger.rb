#!/usr/bin/env ruby 
# -*- coding: utf-8 -*-
require 'syslog/logger'

module Y0shin0
  class Logger < Syslog::Logger
    include ::Logger::Severity

    # noinspection RubyClassVariableUsageInspection
    @@is_first = true
    SEVERITIES = %w(DEBUG INFO WARN ERROR FATAL UNKNOWN)

    # noinspection RubyClassVariableUsageInspection
    def initialize program_name = 'ruby', facility = nil
      @plugin_name = program_name unless @@is_first
      @@is_first = false
      super
    end

    def add(severity, message = nil, progname = nil, &block)
      message = "[#{@plugin_name || 'CORE'}] #{message}"
      super
      return unless Y0shin0::CoreConfig[:main][:show_log]
      severity_name = SEVERITIES[severity]
      case severity
        when DEBUG, INFO then
          if severity == DEBUG && !$DEBUG
            return
          end
          puts("[#{severity_name}]" + message)
        when WARN..UNKNOWN
          STDERR.puts("[#{severity_name}]" + message)
      end
    end
  end
end