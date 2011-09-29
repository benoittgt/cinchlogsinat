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
    File.open(file, 'a') do |f|
      time = Time.now.strftime('%T')
      chan = false
      str  = nil
      msg  = m.message
      
      case m.command
      when 'NOTICE'
        fmt = "[%s] -%s- %s"
      when 'JOIN'
        chan = true
        fmt = "[%s] * %s has joined %s"
      when 'PART'
        chan = true
        fmt = "[%s] * %s has left %s (%s)"
      when 'QUIT'
        fmt = "[%s] * %s has quit (%s)"
      else
        if msg[0..6] == "\x01ACTION"
          msg = msg[7..-1]
          msg.delete!("\x01")
          fmt = "[%s] * %s %s"
        else
          fmt = "[%s] <%s> %s"
        end
      end
      
      p fmt
      if chan
        str = fmt % [time, @@m.user.nick, @@m.channel.name, msg]
      else
        str = fmt % [time, @@m.user.nick, msg]
      end
      f.write(str + "\r\n")
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

  on :join do |m|
    Log << m
  end

  on :part do |m|
    Log << m
  end

  on :quit do |m|
    Log << m
  end

  on :message do |m|
    Log << m
  end
end

bot.start
