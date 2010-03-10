#
# This is a Kernel extension to add event/callbacks, in a generic
# way, to Ruby. This is not nearly as cool as Qt's signal/slot 
# system, but should work for simple projects.
#
# This has -no- threading or process management!
#
# Three events are pre-defined:
#
#  :event_created  -- when a new event is created.
#  :event_emitted  -- when a event is emitted, but only if it
#                     is _NOT_ :event_emitted.
#  :event_removed  -- when a event is removed.
#
# Author:: Randy Carnahan
# Copyright:: Copyright (c) 2009 Randy Carnahan
# License:: Distributed under the same terms as the Ruby language.
#
module Kernel

  # Our events hash. Each key will reference an array of +Proc+
  # objects that are the event callbacks.
  @@events = {
    :event_created => [],
    :event_emitted => [],
    :event_removed => []
  }

  # Holds our silenced events. Events in this array are not emitted
  # if they have been silencted.
  @@silenced_events = []

  # EventError Exception to handle all event related errors.
  class EventError < StandardError
  end

  # Adds the event to the events hash.
  # +event+ must be a Symbol or a String, or else an EventError
  # is raised.
  # The :event_created event is emitted after creation.
  def create_event(event)
    event = event.to_s.to_sym()
    @@events[event] = [] if not @@events.has_key?(event)
    emit_event(:event_created, event)
    return event
  end

  # Removes +event+ from the events hash.
  # The :event_removed event is emitted if the removal was
  # successful.
  def remove_event(event)
    event = event.to_s.to_sym()

    if @@events.has_key?(event)
      @@events.delete(event)
      emit_event(:event_removed, event)
    end

    return event
  end

  # Checks for a specific event, and returns true if it exists as
  # a key in the events hash.
  def has_event?(event)
    event = event.to_s.to_sym()
    return @@events.has_key?(event)
  end

  # Call this method to watch for an event to happen.
  # +event+:: The event to watch.
  # +create_event_if_needed+:: If the event doesn't exist in the events 
  #   has yet, create it.
  # +block+:: The anonymous block to be called when the event happens.
  def observe_event(event, create_event_if_needed=false, &block)
    event = event.to_s.to_sym()

    if not has_event?(event)
      if create_event_if_needed
        create_event(event)
      else
        raise EventError, "No event known by: #{event}"
      end
    end

    @@events[event].push(block)
    return event
  end

  # Call this method when you are ready to announce that an event has happened.
  # +event+:: The event that is happening.
  # The values in the args parameter will be passed to the callback.
  # The :event_emitted event is emitted _after_ all callbacks for a given
  # event have been called and _only_ if a callback was called.
  # The :event_emitted event is _not_ emitted if the :event_emitted was the
  # event being emitted.
  def emit_event(event, *args)
    event = event.to_s.to_sym()

    return false if @@silenced_events.include?(event)

    has_done_callback = false

    if has_event?(event)
      @@events[event].each do |callback|
        callback.call(event, args)
        has_done_callback = true
      end
    else
      raise EventError, "No event known by: #{event}"
    end

    if has_done_callback and event != :event_emitted
      emit_event(:event_emitted, event)
    end
    return has_done_callback
  end

  # This will cause an event's callbacks to _not_ be called when the 
  # event is emitted.
  def silence_event(event)
    event = event.to_s.to_sym()
    @@silenced_events.push(event) unless @@silenced_events.include?(event)
    return event
  end

  # Unsilenced an event if it has previously been silenced.
  def unsilence_event(event)
    event = event.to_s.to_sym()
    return @@silenced_events.delete(event)
  end

end

