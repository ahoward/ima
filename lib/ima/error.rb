module Ima
  class Error < StandardError
    attr_reader :data

    def initialize(*args, **data, &block)
      super(*args, &block)
      @data = data
    end
  end

  def Ima.error!(...)
    raise Error.new(...)
  end

  class Abort < Error
    def initialize(...)
      super(...)
    end

    def status
      @data.fetch(:status){ 1 }
    end
  end

  def Ima.abort!(...)
    raise Abort.new(...)
  end
end
