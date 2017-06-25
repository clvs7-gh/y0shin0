#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

Plugin.create :sound do
  next unless Y0shin0::CoreConfig.is_plugin_active :sound

  @log = Y0shin0::Logger.new('Sound Plugin')

  # Check aplay (ALSA)
  `which aplay > /dev/null 2>&1`
  raise 'ALSA is required!' if $? != 0

  # Load configs
  @cards = Y0shin0::CoreConfig[:main][:cards]
  @sounds = Y0shin0::CoreConfig[:sound][:sounds]
  @voices = Y0shin0::CoreConfig[:sound][:voices]

  def play(sound, voice = true)
    filepath = File.join(ROOT_DIR, 'assets', (voice ? 'voices' : 'sounds'), sound[:file])
    raise 'Invalid sound file!' unless File.file? filepath
    @log.info('Playing : ' + filepath)
    `aplay -q #{filepath} > /dev/null 2>&1 &`
  end

  # Select voice with parsing event
  def select_voice(y_event)
    case y_event.event_name
      when 'nfc' then
        # Filter card by event
        card = @cards.select { |c| y_event.event_data.value == c[:uid] }.first || return
        # Filter voice by filtered card and current state
        @voices.select { |v| (v[:card] == card.name) && (v[:mode] == Y0shin0::State[:mode]) }.sample || return
      else
        nil
    end
  end

  # Select sound with parsing event
  def select_sound(y_event)
    # Filter sounds by event value
    @sounds.select { |s| (s[:trigger] == y_event.event_data.type) }.sample || return
  end

  def select_and_play(y_event, voice = true)
    # Play voice
    sound = voice ? select_voice(y_event) : select_sound(y_event)
    return if sound.nil?
    Delayer::Deferred.new { play(sound, voice) }.trap do |e|
      @log.warn('Can\'t play voice/sound : ' + e.inspect)
    end
  end

  on_event_client do |y_event|
    case y_event.event_name
      when 'system'
        select_and_play y_event, false
      else
        select_and_play y_event
    end
  end

  on_event_server do |y_event|
    select_and_play y_event, false
  end
end
