require 'sinatra'
require 'sqlite3'
require 'json'
require './logger'


db = SQLite3::Database.open "irclogs.db"

get '/' do
  @dbcont = db.execute("SELECT * From irclogs;").reverse
  erb :index
end

get '/logs.json' do
  content_type :json
  @dbcont = db.execute("SELECT * From irclogs;")
  @dbcont.to_json
end