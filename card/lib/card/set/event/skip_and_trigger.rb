class Card
  module Set
    class Event
      # opt into (trigger) or out of (skip) events
      module SkipAndTrigger
        # force skipping this event for all cards in act
        def skip_event! *events
          @full_skip_hash = nil
          force_events events, act_skip_hash
        end

        # force skipping this event for this card only
        def skip_event_in_action! *events
          force_events events, full_skip_hash
        end

        # force triggering this event (when it comes up) for all cards in act
        def trigger_event! *events
          @full_trigger_hash = nil
          force_events events, act_trigger_hash
        end

        # force triggering this event (when it comes up) for this card only
        def trigger_event_in_action! *events
          force_events events, full_trigger_hash
        end

        # hash form of raw skip setting, eg { "my_event" => true }
        def skip_hash
          @skip_hash ||= hash_with_value skip, true
        end

        def trigger_hash
          @trigger_hash ||= hash_with_value trigger, true
        end

        private

        # "applies always means event can run
        # so if skip_condition_applies?, we do NOT skip
        def skip_condition_applies? event, allowed
          return true unless (val = full_skip_hash[event.name.to_s])

          allowed ? val.blank? : (val != :force)
        end

        def trigger_condition_applies? event, required
          return true unless required

          full_trigger_hash[event.name.to_s].present?
        end

        def full_skip_hash
          @full_skip_hash ||= act_skip_hash.merge skip_in_action_hash
        end

        def act_skip_hash
          (act_card || self).skip_hash
        end

        def skip_in_action_hash
          hash_with_value skip_in_action, true
        end

        def full_trigger_hash
          @full_trigger_hash ||= act_trigger_hash.merge trigger_in_action_hash
        end

        def trigger_in_action_hash
          hash_with_value trigger_in_action, true
        end

        def act_trigger_hash
          (act_card || self).trigger_hash
        end

        def hash_with_value array, value
          Array.wrap(array).each_with_object({}) do |event, hash|
            hash[event.to_s] = value
          end
        end

        def force_events events, hash
          events.each { |e| hash[e.to_s] = :force }
        end
      end
    end
  end
end
