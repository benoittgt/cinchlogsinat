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
    logs do
      dir File.join(File.dirname(__FILE__), "logs")
      theme  'default'
      protocol 'http'
      server   'localhost'
      port      80
      path     ''
    end
  end

  verify do
    nick     String
    channels Array
    server do
      address String
      port    (0..65535)
    end
    logdir String
    theme  String
    http_server String
  end
end

class Log
  def self.setup
    @@last_dir = nil
    @@cur_dir  = nil
    @@m = nil
    @@users = {}
    @@theme_dir = File.join(File.dirname(__FILE__), 'themes', Configru.logs.theme)
    
    #FileUtils.mkdir_p(Configru.logs.dir)
    dir
    
    %w[index.html main.css].each do |x|
      File.open(File.join(Configru.logs.dir, x), 'w') do |f|
        f.write File.open(File.join(@@theme_dir, x), 'r').read
      end
    end
    
    File.open(File.join(Configru.logs.dir, 'jquery.hashchange.js'), 'w') do |f|
      f.write File.open(File.join(@@theme_dir, '..', 'jquery.hashchange.js'), 'r').read
    end
  end

  def self.file
    d = dir
    FileUtils.mkdir_p(d)
    File.join(d, "#{@@m.channel.name.gsub('#','+')}.html")
  end

  def self.short_dir
    File.join(Configru.server.address, *Time.now.strftime('%Y/%b/%d').split('/'))
  end

  def self.dir
    @@last_dir = @@cur_dir
    @@cur_dir  = File.join(Configru.logs.dir, short_dir)
    FileUtils.mkdir_p(@@cur_dir)
    
    update_list
    update_index
    
    @@cur_dir
  end

  def self.update_index
    File.open(File.join(@@cur_dir, 'index.html'), 'w') do |f|
      f.write File.open(File.join(@@theme_dir, 'index.html'), 'r').read
    end
  end

  def self.update_list
    return if @@last_dir == @@cur_dir
    File.open(File.join(@@cur_dir, 'list.html'), 'w') do |f|
      Configru.channels.each do |c|
        f.write '<p><a href="' + c + '">' + c + '</a></p>'
      end
    end
  end
  
  def self.add_users(m)
    m.channel.users.keys.map do |user|
      add_user(m, user)
    end
  end
  
  def self.add_user(m, user = nil)
    if user.nil?
      user = m.user
    end
    @@users[user.nick.downcase] ||= []
    @@users[user.nick.downcase] << m.channel if m.channel
    @@users[user.nick.downcase].uniq!
    @@users[user.nick.downcase]
  end
  
  def self.del_user(m)
    if @@users.keys.include?(m.user.nick.downcase)
      @@users[m.user.nick.downcase].each do |chan|
        m.instance_variable_set('@channel', chan)
        add(m)
      end
    end
  end
  
  def self.add(m)
    if !m.channel?
      if m.command == 'QUIT'
        return del_user(m)
      end
      return
    end
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
        add_user(m)
        chan = true
        fmt = "* %s has joined %s"
      when 'PART'
        @@users[m.user.nick.downcase].delete(m.channel)
        chan = true
        fmt = "* %s has left %s (%s)"
      when 'QUIT'
        return del_user(m) unless m.channel
        fmt = "* %s has quit (%s)"
      when 'MODE'
        mode = true
        fmt = "* %s set mode: %s"
      when '353'
        return add_users(m)
      else
        if msg[0..6] == "\x01ACTION"
          msg = msg[7..-1]
          msg.delete!("\x01")
          fmt = "* %s %s"
        else
          fmt = "<%s> %s"
        end
      end
      
      fmt_args = [time]
      fmt_args << @@m.user.nick
      fmt_args << @@m.channel.name if chan
      fmt_args << @@m.params[1..-1].join(' ') if mode
      fmt_args << msg
      
      fmt = HTMLEntities.new.encode(fmt)
      fmt = '<p><span class="date">%s</span> <span class="message ' + m.command + '">' + fmt + '</p>'
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

  on '353' do |m|
    Log << m
  end

  on :message, /^.logs$/ do |m|
    # Yes, this IS hacky...
    url  = ::Configru.logs.protocol + '://'  + ::Configru.logs.server
    url += ':' + ::Configru.logs.port.to_s unless ::Configru.logs.port == 80
    url += '/' + ::Configru.logs.path unless ::Configru.logs.path.empty?
    url += "/#{::Log.short_dir}#{m.channel.name}".gsub('//','/')
    p m
    p m.methods
    msg = ::Cinch::Message.new(":#{m.bot.nick}!user@host PRIVMSG #{m.channel} :#{m.user.nick}: #{url}", m.bot)
    m.reply msg, true
    ::Log.add(m2)
  end
end

bot.start
