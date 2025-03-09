module Ima
  class RateLimiter
    TLDR = <<~____

      a simple, durable, stateful, multi-thread and multi-process safe rate_limiter

    ____

    def RateLimiter.verbose
      Ima.verbose
    end

    def RateLimiter.state_dir
      Ima.dir('rate_limiter')
    end

    def RateLimiter.state_file_for(name:, rate:)
      slug = name.to_s.strip.scan(/[0-9a-zA-Z_]+/).join
      rate = rate.to_f.round(2).to_s.gsub('.', '-')
      basename = [slug, rate].join('--')

      File.expand_path(File.join(RateLimiter.state_dir, "#{ basename }.json"))
    end

    def initialize(name: 'default', rate: 20, rps: nil, rpm: nil, rph: nil, rpd: nil, pad: 0.00420, verbose: RateLimiter.verbose)
      @name = name.to_s.strip

      @rate = (rps || rate).to_f.abs

      if rpm
        @rate = (rpm.to_f / (60)).abs
      end

      if rph
        @rate = (rph.to_f / (60 * 60)).abs
      end

      if rpd
        @rate = (rpd.to_f / (60 * 60 * 24)).abs
      end

      @pad = pad.to_f
      @verbose = !!verbose

      @mutex = Mutex.new
      @state_file = RateLimiter.state_file_for(name:@name, rate:@rate)
      @lock_file = Lockfile.new(@state_file + '.lock')

      @requests = []
    end

    def limit(&block)
      loop do
        ok = false
        timeout = 0
        now = Time.now

        transaction do
          requests = @requests.select{|t| (now - t) < 1.0}

          if requests.size < @rate
            ok = true
            @requests << now
          else
            ok = false
            timeout = 1/@rate + @pad
          end
        end

        if ok
          return block.call
        else
          sleep(timeout)
        end
      end
    end

    def sleep(seconds)
      warn "\nRateLimiter[#{ @name }].sleep(#{ seconds })\n" if @verbose
      Kernel.sleep(seconds)
    end

    def transaction(&block)
      lock! do
        load_state!

        begin
          block.call
        ensure
          save_state!
        end
      end
    end

    def lock!(&block)
      FileUtils.mkdir_p(File.dirname(@lock_file.path))

      @mutex.synchronize do
        @lock_file.lock do
          block.call
        end
      end
    end

    def load_state!
      state =
        if test(?s, @state_file)
          JSON.parse(IO.binread(@state_file))
        else
          current_state
        end

      requests = state.fetch('requests'){ [] }.map{|it| Time.parse(it.to_s)}

      now = Time.now

      @requests = requests.select{|time| (now - time).floor <= 60}
    end

    def save_state!
      tmp = @state_file + ".tmp.#{ SecureRandom.uuid_v7 }"
      FileUtils.mkdir_p(File.dirname(tmp))

      state = current_state
      json = JSON.pretty_generate(state)
      IO.binwrite(tmp, json)

      FileUtils.mv(tmp, @state_file)
    ensure
      FileUtils.rm_f(tmp) if tmp
    end

    def current_state
      {
        'name'       => @name,
        'rate'       => @rate,
        'requests'   => @requests.map{|it| it.iso8601(2)},
      }
    end
  end
end
