#!/usr/bin/env ruby

begin
  require 'fileutils'
rescue
  require 'FileUtils'
end
require 'configru'
require 'cinch'
require 'cinch/plugins/basic_ctcp'

Configru.load do
  first_of 'config.yml'
  defaults do
    nick     'cinchbot'
    channels ['#bots', '#programming']
    server do
      address 'irc.tenthbit.net'
      port    6667
    end
    logdir File.join(File.dirname(__FILE__), "logs")
  end

  verify do
    nick     String
    channels Array
    server do
      address String
      port    (0..65535)
    end
    logdir String
  end
end

class Log
  def self.setup
    @@m = nil
  end

  def self.file
    d = dir
    FileUtils.mkdir_p(d)
    File.join(d, "#{@@m.channel.name.gsub('#','+')}.txt")
  end

  def self.dir
    File.join(Configru.logdir, Configru.server.address, *Time.now.strftime('%Y/%m/%d').split('/'))
  end

  def self.add(m)
    @@m = m
    File.open(file, 'w') do |f|
      time = Time.now.strftime('%T')
      f.write("[#{time}] <#{@@m.user.nick}> #{@@m.message}")
    end
  end

  def self.<<(m)
    self.add(m)
  end
end

Log.setup

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = Configru.server.address
    c.port     = Configru.server.port
    c.channels = Configru.channels
    c.nick     = Configru.nick
    c.plugins.plugins = [Cinch::Plugins::BasicCTCP]
    c.plugins.options[Cinch::Plugins::BasicCTCP][:commands] = [:version, :time, :ping]
  end
    
  on :message do |m|
    Log << m
  end
end

bot.start
