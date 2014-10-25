require 'sinatra'
require './logger'
require 'SQLite3'

db = SQLite3::Database.open "irclogs.db"

get '/' do
  @dbcont = db.execute("SELECT * From irclogs;")
  erb :index
end