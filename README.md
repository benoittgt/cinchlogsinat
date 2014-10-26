##Cinch plugin for irc : logs printed on Sinatra

I've started a bot from [logbot](https://github.com/duckinator/logbot) made by [duckinator](https://github.com/duckinator). Thanks bro. 
I've added sqlite, sinatra and bootstrap. 

The project is not well coded but it's work. 

To start the project
 * `git clone https://github.com/BenoitTigeot/cinchlogsinat.git`
 * `bundle`
 * Create empty db `touch irclogs.db`
 * Create your config file from `config.yml.dist` with the name `config.yml`
 * You can run the bot alone with `ruby cinchbot.rb`
 * You can run Sinatra with `ruby webserver.rb`

Fork it ! 

### To Do

* Big refactoring
* Security check
* Tests
* d3.js stats
* cinch status from Sinatra
* ...git a

### Licence

[MIT LICENCE](http://www.opensource.org/licenses/mit-license)
