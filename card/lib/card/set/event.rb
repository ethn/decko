class Card
  module Set
    # Events are the building blocks of the three transformative card actions: _create_, _update_, and _delete_. (The fourth kind of action, _read_, does not transform cards, and is associated with {Card::Format views}, not events).
    #
    # Whenever you create, update, or delete a card, the card goes through three phases:
    #   * __validation__ makes sure all the data is in order
    #   * __storage__ puts the data in the database
    #   * __integration__ deals with any ramifications of those changes
    #
    #
    module Event
      include DelayedEvent

      def event event, stage_or_opts={}, opts={}, &final
        if stage_or_opts.is_a? Symbol
          opts[:in] = stage_or_opts
        else
          opts = stage_or_opts
        end
        process_stage_opts opts

        Card.define_callbacks event
        define_event event, opts, &final
        set_event_callbacks event, opts
      end

      private

      def define_event event, opts, &final
        final_method_name = "#{event}_without_callbacks" # should be private?
        class_eval do
          define_method final_method_name, &final
        end

        if with_delay? opts
          define_delayed_event_method event, final_method_name
        else
          define_event_method event, final_method_name
        end
      end

      def with_delay? opts
        DELAY_STAGES.include?(opts[:after]) || DELAY_STAGES.include?(opts[:before])
      end

      def process_stage_opts opts
        if opts[:after] || opts[:before]
          # ignore :in options
        elsif opts[:in]
          opts[:after] =
            callback_name opts.delete(:in), opts.delete(:after_subcards)
        end
        opts[:on] = [:create, :update] if opts[:on] == :save
      end

      def callback_name stage, after_subcards=false
        name = after_subcards ? "#{stage}_final_stage" : "#{stage}_stage"
        name.to_sym
      end

      def define_event_method event, call_method
        class_eval do
          define_method event do
            log_event_call event
            run_callbacks event do
              send call_method
            end
          end
        end
      end

      def set_event_callbacks event, opts
        opts[:set] ||= self
        [:before, :after, :around].each do |kind|
          next unless (object_method = opts.delete(kind))
          Card.class_eval do
            set_callback(
              object_method, kind, event,
              prepend: true, if: proc { |c| c.event_applies?(opts) }
            )
          end
        end
      end
    end
  end
  def deserialize_for_active_job! attr
    attr.each do |attname, val|
      instance_variable_set("@#{attname}", val)
    end

    include_set_modules
  end

  def with_env_and_auth env, auth
    # If active jobs (and hence the integrate_with_delay events) don't run
    # in a background process then Card::Env.deserialize! decouples the
    # controller's params hash and the Card::Env's params hash with the
    # effect that params changes in the CardController get lost
    # (a crucial example are success params that are processed in
    # CardController#update_params_for_success)
    return yield if Decko.config.active_job.queue_adapter == :inline
    Card::Auth.with auth do
      Card::Env.with env do
        yield
      end
    end
  end

  def serialize_for_active_job
    serializable_attributes.each_with_object({}) do |name, hash|
      hash[name] = instance_variable_get("@#{name}")
    end
  end

  def serialize_value value
    # ActiveJob doesn't accept symbols and Time as arguments
    case value
      when Symbol
        { value: value.to_s, type: "symbol" }
      when Time
        { value: value.to_s, type: "time" }
      when Hash
        {
            value: value.each_with_object({}) { |(k, v), h| h[k] = serialize_value(v) },
            type: "hash"
        }
      when ActionController::Parameters
        serialize_value value.to_unsafe_h
      else
        { value: value }
    end
  end

  def deserialize_value val, type
    case type
      when "symbol"
        val.to_sym
      when "time"
        DateTime.parse val
      when "hash"
        val.each_with_object({}) do |(k, v), h|
          h[k] = deserialize_value v[:value], v[:type]
        end
      else
        val
    end
  end

  def log_event_call event
    Rails.logger.debug "#{name}: #{event}"
    # puts "#{name}: #{event}"
    # puts "#{Card::ActManager.to_s}".green
  end
end
