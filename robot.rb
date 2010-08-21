require 'cinch'

class QuestionRecord < Struct.new(:who, :what, :time)
	def to_s
		"[#{time.asctime}] #{who} had a question, '#{what}'"
	end
end

bot = Cinch::Bot.new do
	configure do |c|
		c.nick = "HacketyRobot"
		c.password = ""
		c.server = "irc.freenode.org"
		c.channels = ["#hacketyhack"]
		@users = {}
	end

	on :message, "hello" do |m|
		m.reply "Hello, #{m.user.nick}"
	end

	on :message, /\?/ do |m|
		@users[m.user.nick] ||= []
		if @users[m.user.nick].length == 0
			m.channel.send "#{m.user.nick}: Thanks for asking a question! You can also get help here: http://bit.ly/hacketyhelp"
		end
		@users[m.user.nick] << QuestionRecord.new(m.user.nick, m.message, Time.new)
		m.channel.send "#{m.user.nick}: your question has been recorded."
	end

	on :channel, /^!question (.+)/ do |m, nick|
		if nick == bot.nick
			m.reply "That's me!"
		elsif @users.key?(nick)
			@users[nick].each do |qr|
				m.reply qr.to_s
			end
		else
			m.reply "I haven't seen #{nick}"
		end
	end
end

bot.start

