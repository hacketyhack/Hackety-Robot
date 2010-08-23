require 'cinch'
require 'sqlite3'

DB = SQLite3::Database.new( "db.sqlite3" )
DB.results_as_hash = true

class Seen < Struct.new(:who)

	#return an array of everyone we've seen
	def self.find_all
		nicks = DB.execute("select * from seen")
		users = {}
		nicks.each do |nick|
			users[nick['who'].to_sym] = true
		end
		users
	end

	#save to the db
	def save
		DB.execute("insert into seen(who) values(:who)", 'who' => who)
	end
end

class Question < Struct.new(:who, :what, :time)
	def to_s
		"[#{time.asctime}] #{who} had a question, '#{what}'"
	end
	def save
		DB.execute("insert into questions(who, what, time) values(:who, :what, :time)", 'who'=> who, 'what'=> what, 'time' => time.to_s)
		
	end
	def self.find_for_nick nick
		questions = DB.execute("select * from questions where who = ? limit 5", nick)
		questions.collect{|q| Question.new(q['who'], q['what'], Time.parse(q['time'])) }
	end
end

bot = Cinch::Bot.new do
	configure do |c|
		c.nick = "HacketyRobot"
		c.password = ""
		c.server = "irc.freenode.org"
		c.channels = ["#hacketyhack"]
		@users = Seen.find_all
	end

	on :message, "hello" do |m|
		m.reply "Hello, #{m.user.nick}"
	end

	on :message, /\?/ do |m|
		unless @users.key? m.user.nick.to_sym
			m.channel.send "#{m.user.nick}: Thanks for asking a question! You can also get help here: http://bit.ly/hacketyhelp"
			seen = Seen.new(m.user.nick)
			seen.save
			@users[m.user.nick.to_sym] = true
		end
		qr = Question.new(m.user.nick, m.message, Time.new)
		qr.save
		m.channel.send "#{m.user.nick}: your question has been recorded."
	end

	on :channel, /^!question (.+)/ do |m, nick|
		if nick == bot.nick
			m.reply "That's me!"
		elsif @users.key?(nick.to_sym)
			m.reply "The last 5 questions by #{nick} are:"
			Question.find_for_nick(nick).each do |qr|
				m.reply qr.to_s
			end
			m.reply "That's all!"
		else
			m.reply "I haven't seen #{nick}"
		end
	end
end

bot.start

