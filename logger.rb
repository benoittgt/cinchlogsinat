require 'sqlite3'

class Log
  def self.setup
    @@last_dir = nil
    @@cur_dir  = nil
    @@theme_dir = File.join(File.dirname(__FILE__), 'theme')
    @@log_dir = Configru.logs.dir
    
    @@db = SQLite3::Database.open "irclogs.db"
    @@db.execute "CREATE TABLE IF NOT EXISTS irclogs(Id INTEGER PRIMARY KEY, timestamp TEXT, nick TEXT, ircmessage TEXT)"

    dir
  end


  def self.find_file(m)
    File.join(dir, "#{m.channel.name.gsub('#','+')}.txt")
  end

  def self.short_dir
    File.join(Configru.server, *Time.now.strftime('%Y/%b/%d').split('/'))
  end

  def self.dir
    @@cur_dir  = File.join(@@log_dir, short_dir)
    FileUtils.mkdir_p(@@cur_dir)

    @@cur_dir
  end

  def self.add(m)
    # begin
      #db = SQLite3::Database.open "irclogs.db"

      return unless m.channel?

      File.open(find_file(m), 'a') do |f|
        time = Time.now.strftime("%e %b %Y %H:%M:%S")
        chan = false
        mode = false
        str  = nil
        msg  = m.message
        return unless msg

        case m.command
        when 'NOTICE'
          fmt = "-%s- %s"
        when 'JOIN'
          chan = false
          fmt = "* %s has joined %s"
        when 'PART'
          chan = false
          fmt = "* %s has left %s (%s)"
        when 'QUIT'
          chan = false
          fmt = "* %s has quit (%s)"
        when 'MODE'
          mode = false
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

        fmt_args = [time]
        fmt_args << m.user.nick
        fmt_args << m.channel.name if chan
        fmt_args << m.params[1..-1].join(' ') if mode
        fmt_args << msg

        fmt = '[%s] ' + fmt

        str = fmt % fmt_args
        f.write(str + "\r\n")

        @@db.execute( "INSERT INTO irclogs ( timestamp, nick, ircmessage ) VALUES ( ?, ?, ? )", [time, m.user.nick, msg])
        sqllast = @@db.execute ("SELECT * FROM irclogs ORDER BY Id DESC LIMIT 1")
        puts time + " SQlite >> #{sqllast}"

      end
    # rescue SQLite3::Exception => e
    #   puts time + " SQlite >> Exception occured"
    #   puts e
    # ensure
    #   @@db.close if @@db
    # end
  end

  def self.<<(m)
    self.add(m)
  end
end