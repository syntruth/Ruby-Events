#
# This is a Kernel extension to add event/callbacks, in a generic
# way, to Ruby. This is not nearly as cool as Qt's signal/slot 
# system, but should work for simple projects.
#
# This has -no- threading or process management!
#
#
# Author:: Randy Carnahan
# Copyright:: Copyright (c) 2009 Randy Carnahan
# License:: Distributed under the same terms as the Ruby language.
#
module Kernel

  # Our events hash. Each key will reference an array of +Proc+
  # objects that are the event callbacks.
  @@events = {}

  # EventError Exception to handle all event related errors.
  class EventError < StandardError
  end

  # Adds the event to the events hash.
  # +event+ must be a Symbol or a String, or else an EventError
  # is raised.
  def create_event(event)
    unless event.is_a?(Symbol) or event.is_a?(String)
      raise EventError, "Event Name must be a string or a symbol!"
    end
    event = event.to_sym() if event.is_a?(String)
    @@events[event] = [] if not @@events.has_key?(event)
    return
  end

  # Removes +event+ from the events hash. Note, all callbacks are
  # removed as well; callbacks are not notified of this!
  # Though, you might add a +:event_removed+ event and then emit
  # that event after you remove an event. :D
  def remove_event(event)
    unless event.is_a?(Symbol) or event.is_a?(String)
      raise EventError, "Event Name must be a string or a symbol!"
    end
    event = event.to_sym() if event.is_a?(String)
    if @@events.has_key?(event)
      return @@events.delete(event)
    end
    return
  end

  # Checks for a specific event, and returns true if it exists as
  # a key in the events hash.
  def has_event?(event)
    unless event.is_a?(Symbol) or event.is_a?(String)
      raise EventError, "Event Name must be a string or a symbol!"
    end
    event = event.to_sym() if event.is_a?(String)
    return @@events.has_key?(event)
  end

  # Call this method to watch for an event to happen.
  # +event+:: The event to watch.
  # +create_event_if_needed+:: If the event doesn't exist in the events 
  #   has yet, create it.
  # +block+:: The anonymous block to be called when the event happens.
  def observe_event(event, create_event_if_needed=false, &block)
    event = event.to_sym() if event.is_a?(String)
    if not has_event?(event)
      if create_event_if_needed
        create_event(event)
      else
        raise EventError, "No event known by: #{event}"
      end
    end
    @@events[event].push(block)
    return
  end

  # Call this method when you are ready to announce that an event has happened.
  # +event+:: The event that is happening.
  # The values in the args parameter will be passed to the callback.
  def emit_event(event, *args)
    has_done_callback = false
    event = event.to_sym() if event.is_a?(String)
    if has_event?(event)
      @@events[event].each do |callback|
        callback.call(event, args)
        has_done_callback = true
      end
    else
      raise EventError, "No event known by: #{event}"
    end
    return has_done_callback
  end

end

