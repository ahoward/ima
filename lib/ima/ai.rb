module Ima
  module AI
    def AI.provider
      AI::Groq
    end

    def AI.completion_for(prompt, temperature:0.7, format:'txt')
      provider.completion_for(prompt, temperature:, format:)
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
      (words.size * 1/words_per_token).to_i
    end

    class Groq
      def Groq.api_key
        Ima.setting_for(:groq, :api_key){ ENV.fetch('GROQ_API_KEY') }
      end

      def Groq.model
        Ima.setting_for(:groq, :model){ 'llama-3.3-70b-versatile' }
      end

      @@MAX_TOKENS = 128_000
      @@TIMEOUT = 420

      @@RPM = 60
      @@RATE_LIMTER = RateLimiter.new(name: 'groq', rpm: @@RPM - 1)

      attr_reader :client

      def initialize(api_key: Groq.api_key, timeout: @@TIMEOUT)
        @api_key = api_key
        @timeout = timeout
        @client = ::Groq::Client.new(api_key: @api_key, model_id: Groq.model, timeout: @timeout)
      end

      def completion_for(*args, role:'user', system:nil, prompt:nil, temperature:nil, format:nil)
        content = [prompt || args].join("\n")
        Groq.try_hard do
          Groq.rate_limit do
            client.chat(content).fetch('content')
          end
        end
      end

      def Groq.completion_for(...)
        new.completion_for(...)
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
