require 'sinatra'
require './logger'
require 'sqlite3'

db = SQLite3::Database.open "irclogs.db"

get '/' do
  @dbcont = db.execute("SELECT * From irclogs;").reverse
  erb :index
end