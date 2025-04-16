module Ima
  class Task
    class DSL < ::BasicObject
      def DSL.read(file)
        DSL.parse(file:)
      end

      def DSL.parse(code = nil, file:nil)
        if file
          code = ::IO.binread(file)
        end

        raise ::ArgumentError.new('no code') unless code

        dsl = DSL.new
        dsl.eval(code)
        dsl.data
      end

      def initialize
        @data = {}
      end

      def eval(code)
        ::Object.instance_method(:instance_eval).
          bind(self).
          call(code)
      end

      def data
        @data
      end

      def model(*args)
        if args.empty?
          @data[:model]
        else
          @data[:model] = args.join
        end
      end

      def context(*args)
        if args.empty?
          @data[:context]
        else
          @data[:context] = args.join
        end
      end

      def system(*args)
        if args.empty?
          @data[:system]
        else
          @data[:system] = args.join
        end
      end

      def instructions(*args)
        if args.empty?
          @data[:instructions]
        else
          @data[:instructions] = args.join
        end
      end
    end
  end
end
