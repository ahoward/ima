# -*- encoding : utf-8 -*-
module Ima
#
  require_relative 'ima/_lib.rb'

  Ima.load_dependencies!

#
  def Ima.defaults
    @defaults ||= (
      dir = File.join(Dir.home, '.ima')
      verbose = false

      Map.for({
        dir:,
        verbose:,
      })
    )
  end

#
  def Ima.env
    @env ||= (
      dir = ENV['IMA_DIR']
      verbose = Ima.cast ENV['IMA_VERBOSE'], :boolean

      Map.for({
        dir:,
        verbose:,
      })
    )
  end

#
  def Ima.dir(*args)
    dir = env.dir || defaults.dir
    File.join(dir, *args)
  end

  def Ima.tmp(*args)
    tmp = Ima.dir('tmp')
    File.join(tmp, *args)
  end

#
  def Ima.config
    @config ||= (
      if test(?e, config_path)
        Map.for(YAML.load(IO.binread(config_path)))
      else
        Map.new
      end
    )
  end

  def Ima.config_path
    Ima.dir('config.yml')
  end

#
  def Ima.settings
    @settings ||= (
      defaults.apply(env).apply(config)
    )
  end

  def Ima.setting_for(*key, &block)
    unless block || settings.has?(*key)
      Ima.error!("no setting for #{ key.inspect }")
    end

    settings.has?(*key) ? settings.get(*key) : block.call
  end

#
  def Ima.verbose
    Ima.setting_for(:verbose)
  end

#
  require_relative 'ima/error.rb'
  require_relative 'ima/cast.rb'
  require_relative 'ima/rate_limiter.rb'
  require_relative 'ima/ai.rb'
  require_relative 'ima/task.rb'
end
