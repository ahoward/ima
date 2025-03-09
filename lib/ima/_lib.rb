module Ima
  VERSION = '0.4.2'

  class << Ima
    def version
      VERSION
    end

    def repo
      'https://github.com/ahoward/ima'
    end

    def summary
      <<~____
        ima # WIP
      ____
    end

    def description
      <<~____
        ima # WIP
      ____
    end

    def libs
      %w[
        fileutils
        io/wait
        json
        securerandom
        thread
        time
        yaml
      ]
    end

    def dependencies
      {
        'parallel'            => ['parallel', '~> 1.26'],
        'map'                 => ['map', '~> 6.6'],
        'front_matter_parser' => ['front_matter_parser', '~> 1.0'],
        'lockfile'            => ['lockfile', '~> 2.1'],
        'groq'                => ['groq', '~> 0.3'],
        'clee'                => ['clee', '~> 0.4'],
      }
    end

    def libdir(*args, &block)
      @libdir ||= File.dirname(File.expand_path(__FILE__))
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call
        ensure
          $LOAD_PATH.shift
        end
      end
    end

    def load(*libs)
      libs = libs.join(' ').scan(/[^\s+]+/)
      libdir { libs.each { |lib| Kernel.load(lib) } }
    end

    def load_dependencies!
      libs.each do |lib|
        require lib
      end

      begin
        require 'rubygems'
      rescue LoadError
        nil
      end

      has_rubygems = defined?(gem)

      dependencies.each do |lib, dependency|
        gem(*dependency) if has_rubygems
        require(lib)
      end
    end
  end
end
