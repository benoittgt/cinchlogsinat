#!/usr/bin/env ruby

begin
  require 'fileutils'
rescue
  require 'FileUtils'
end
require 'htmlentities'
require 'configru'
require 'cinch'
require 'cinch/plugins/basic_ctcp'

Configru.load do
  first_of 'config.yml'
  defaults do
    nick     'cinchbot'
    channels ['#duxos']
    server do
      address 'irc.freenode.net'
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
    @@last_dir = nil
    @@cur_dir  = nil
    @@m = nil
  end

  def self.file
    d = dir
    FileUtils.mkdir_p(d)
    File.join(d, "#{@@m.channel.name.gsub('#','+')}.html")
  end

  def self.dir
    @@last_dir = @@cur_dir
    @@cur_dir  = File.join(Configru.logdir, Configru.server.address, *Time.now.strftime('%Y/%b/%d').split('/'))
    @@cur_dir
  end

  def self.add(m)
    return unless m.channel
    @@m = m
    File.open(file, 'a') do |f|
      time = Time.now.strftime('%T')
      chan = false
      mode = false
      str  = nil
      msg  = m.message
      
      case m.command
      when 'NOTICE'
        fmt = "-%s- %s"
      when 'JOIN'
        chan = true
        fmt = "* %s has joined %s"
      when 'PART'
        chan = true
        fmt = "* %s has left %s (%s)"
      when 'QUIT'
        fmt = "* %s has quit (%s)"
      when 'MODE'
        mode = true
        p m
        fmt = "* %s set mode: %s"
      else
        if msg[0..6] == "\x01ACTION"
          msg = msg[7..-1]
          msg.delete!("\x01")
          fmt = "* %s %s"
        else
          fmt = "<%s> %s"
        end
      end
      
      p fmt
      fmt_args = [time]
      fmt_args << @@m.user.nick
      fmt_args << @@m.channel.name if chan
      fmt_args << @@m.params[1..-1].join(' ') if mode
      fmt_args << msg
      
      fmt = HTMLEntities.new.encode(fmt)
      fmt = '<p><span class="date">%s</span> <span class="message ' + m.command + '">' + fmt + '</p>'
      puts "str = #{fmt.inspect} % #{fmt_args.inspect}"
      str = fmt % fmt_args
      f.write(str + "\r\n")
    end
  end

  def self.<<(m)
    self.add(m)
  end

  # Wtf is this and why did I add it? :|
  def log
    Proc.new{|m| Log << m }
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

  on :mode do |m|
    Log << m
  end

  on :message do |m|
    Log << m
  end
end

bot.start
