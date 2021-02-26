# Does not require activesupport/etc, ensure you use this in an ActiveSupport
# environment such as running rails app.

module JsonTaggedLogging
  module Formatter # :nodoc:
    # This method is invoked when a log event occurs.
    def call(severity, timestamp, progname, msg)
      # ActiveSupport::TaggedLogging::Formatter has this implementation
      #
      # super(severity, timestamp, progname, "#{tags_text}#{msg}")
      msg = begin
        # This branch handles the interop with lograge, when the "msg" is already
        # a line like  ... {\"method\":\"GET\",\"path\":\"/admin/login\",\"format\":\"html\",\"contr..
        # in that case, let's augment, not mangle it.
        JSON.parse!(msg)
      rescue JSON::ParserError
        { msg: msg }
      end
      tags = Array(current_tags).collect do |t|
        if (t.is_a?(Symbol) || t.is_a?(String))
          { t => ""}
        else
          t.as_json
        end
      end.inject(:merge)
      msg.merge!(tags) if tags
      msg.merge({severity: severity, progname: progname}).reject{|k,v| v.nil? }.to_json + "\n"
    end

    def tagged(*tags)
      new_tags = push_tags(*tags)
      yield self
    ensure
      pop_tags(new_tags.size)
    end

    def push_tags(*tags)
      tags.flatten!
      tags.reject!(&:blank?)
      current_tags.concat tags
      tags
    end

    def pop_tags(size = 1)
      current_tags.pop size
    end

    def clear_tags!
      current_tags.clear
    end

    def current_tags
      # We use our object ID here to avoid conflicting with other instances
      thread_key = @thread_key ||= "activesupport_tagged_logging_tags:#{object_id}"
      # Improvement from unmerged PR https://github.com/rails/rails/pull/37566 to
      # work better with fibers.
      Thread.current.thread_variable_set(thread_key, []) unless Thread.current.thread_variable_get(thread_key)
      Thread.current.thread_variable_get(thread_key)
    end

  end

  module LocalTagStorage # :nodoc:
    attr_accessor :current_tags

    def self.extended(base)
      base.current_tags = []
    end
  end

  def self.new(logger)
    logger = logger.clone

    if logger.formatter
      logger.formatter = logger.formatter.dup
    else
      # Ensure we set a default formatter so we aren't extending nil!
      logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
    end

    logger.formatter.extend Formatter
    logger.extend(self)
  end

  delegate :push_tags, :pop_tags, :clear_tags!, to: :formatter

  def tagged(*tags)
    if block_given?
      formatter.tagged(*tags) { yield self }
    else
      logger = JSONTaggedLogging.new(self)
      logger.formatter.extend LocalTagStorage
      logger.push_tags(*formatter.current_tags, *tags)
      logger
    end
  end

  def flush
    clear_tags!
    super if defined?(super)
  end
end
