module Ima
  module AI
    def AI.provider
      AI::Groq
    end

    def AI.completion_for(...)
      provider.completion_for(...)
    end

    def AI.json_parse_liberally(json)
      begin
        JSON.parse(json)
      rescue => error
        begin
          json.gsub!('```json', '')
          json.gsub!('```', '')
          JSON.parse(json)
        rescue
          raise error
        end
      end
    end

    def AI.count_tokens(*args)
      string = args.join("\n")
      words = string.scan(/\w+/)
      words_per_token = 3.0/4.0
      (words.size * 1/words_per_token).to_i + 420
    end

    class Groq
      def Groq.api_key
        Ima.cast(
          Ima.setting_for(:groq, :api_key){ ENV.fetch('GROQ_API_KEY') },
          :string
        )
      end

      def Groq.model_id
        Ima.cast(
          Ima.setting_for(:groq, :model_id){ 'llama-3.3-70b-versatile' },
          #Ima.setting_for(:groq, :model_id){ 'qwen-2.5-coder-32b' },
          :string
        )
      end

      def Groq.timeout
        Ima.cast(
          Ima.setting_for(:groq, :timeout){ 420 },
          :number
        )
      end

      # FIXME
      @@MAX_TOKENS = 128_000
      @@RPM = 60
      @@RATE_LIMTER = RateLimiter.new(name: 'groq', rpm: @@RPM - 1)

      attr_reader :api_key
      attr_reader :model_id
      attr_reader :timeout

      def initialize(api_key:nil, model_id:nil, timeout:nil)
        @api_key = api_key || Groq.api_key
        @model_id = model_id || Groq.model_id
        @timeout = timeout || Groq.timeout
      end

      def client_for(**kws)
        args = kws[:client] || {}

        args[:api_key] = (kws[:api_key] || api_key)
        args[:model_id] = (kws[:model_id] || kws[:model] || model_id)
        args[:timeout] = (kws[:timeout] || timeout)

        ::Groq::Client.new(**args)
      end

      def Groq.instance
        new
      end

      def Groq.completion_for(...)
        instance.completion_for(...)
      end

      def completion_for(*args, **kws, &block)
        client = client_for(**kws)

        system = kws[:system]
        prompt = [kws[:prompt] || args].join("\n").strip

        messages =
          [].tap do |m|
            if Task.present?(system)
              m << {'role' => 'system', 'content' => system.to_s}
            end

            if Task.present?(prompt)
              m << {'role' => 'user', 'content' => prompt.to_s}
            end
          end

        Groq.try_hard do
          Groq.rate_limit do
            client.chat(messages).fetch('content')
          end
        end
      end

      def Groq.rate_limit(&block)
        @@RATE_LIMTER.limit(&block)
      end

      def Groq.try_hard(*args, &block)
        if @try_hard == false
          return block.call
        end

        n = 6
        errors = []
        fatal = [
          RangeError,
          NameError,
          ArgumentError,
          Faraday::BadRequestError,
          Faraday::ClientError
        ]

        n.times do |i|
          begin
            return block.call
          rescue => error
            raise error if fatal.include?(error.class)
            errors.push(error)
            s = (2 ** (i + 2))
            warn "Groq.try_hard: sleep(#{ s }), #{ error.class }[#{ error.message }]"
            sleep(s)
          end
        end

        raise errors.last
      end

      def Groq.try_hard=(try_hard)
        @try_hard = !!try_hard
      end
    end
  end
end
