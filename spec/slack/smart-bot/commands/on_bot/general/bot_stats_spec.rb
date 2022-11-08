RSpec.describe SlackSmartBot, "bot_stats" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    it "is not allowed when master admin" do
      send_message "!bot stats", from: user, to: channel
      message = "Only Master admin users on a private conversation with the bot can see this kind of bot stats"
      expect(buffer(to: channel, from: :ubot).join).to match(/#{message}/)
    end

    it "is allowed when normal user" do
      send_message "!bot stats", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Bot stats for <@#{USER1}>/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Total calls <##{CBOT1CM}>/)
      expect(buffer(to: channel, from: :ubot).join).to match(/You are the/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/SmartBots/)
      expect(buffer(to: channel, from: :ubot).join).to match(/From Channel/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/Users\s\-/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Commands/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Message type/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/Last activity/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :uadmin

    it "is not allowed when master admin" do
      send_message "!bot stats", from: user, to: channel
      message = "Only Master admin users on a private conversation with the bot can see this kind of bot stats"
      expect(buffer(to: channel, from: :ubot).join).to match(/#{message}/)
    end

    it "is allowed when normal user" do
      send_message "!bot stats", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Bot stats for <@#{USER1}>/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Total calls <##{CMASTER}>/)
      expect(buffer(to: channel, from: :ubot).join).to match(/You are the/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/SmartBots/)
      expect(buffer(to: channel, from: :ubot).join).to match(/From Channel/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/Users\s\-/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Commands/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Message type/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/Last activity/)
    end
  end

  describe "on extended channel" do
    it "is not allowed when master admin" do
      send_message "!bot stats'", from: :uadmin, to: :cext1
      message = "I don't understand"
      expect(buffer(to: :cext1, from: :ubot).join).to match(/#{message}/)
    end
    it "is not allowed when normal user" do
      send_message "!bot stats'", from: :user1, to: :cext1
      message = "I don't understand"
      expect(buffer(to: :cext1, from: :ubot).join).to match(/#{message}/)
    end
  end

  describe "on external channel not extended" do
    it "is not allowed when master admin" do
      command = "!bot stats"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/Take in consideration when on external calls/)
    end
    it "is not allowed when normal user" do
      command = "!bot stats"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :user1, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/Take in consideration when on external calls/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.uadmin.ubot
    dm_user = DIRECT.user1.ubot
    user = :uadmin

    it "is allowed when normal user" do
      send_message "!bot stats", from: :user1, to: dm_user
      expect(buffer(to: dm_user, from: :ubot).join).to match(/Bot stats for <@#{USER1}>/)
      expect(buffer(to: dm_user, from: :ubot).join).to match(/Total calls\*:/)
      expect(buffer(to: dm_user, from: :ubot).join).to match(/You are the/)
      expect(buffer(to: dm_user, from: :ubot).join).to match(/SmartBots/)
      expect(buffer(to: dm_user, from: :ubot).join).to match(/From Channel/)
      expect(buffer(to: dm_user, from: :ubot).join).not_to match(/Users\*\s\-/)
      expect(buffer(to: dm_user, from: :ubot).join).to match(/Commands/)
      expect(buffer(to: dm_user, from: :ubot).join).to match(/Message type/)
      expect(buffer(to: dm_user, from: :ubot).join).not_to match(/Last activity/)
    end

    it "is allowed when master admin" do
      send_message "!bot stats", from: :uadmin, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to match(/Bot stats for/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Total calls\*:/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/You are the/)
      expect(buffer(to: channel, from: :ubot).join).to match(/SmartBots/)
      expect(buffer(to: channel, from: :ubot).join).to match(/From Channel/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Users\*\s\-/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Commands/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Message type/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Last activity/)
    end

    it "returns stats" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
    end
    it "excludes master admins" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "hi bot", from: user, to: channel
      send_message "bot stats exclude masters", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Excluding master admins/)
      expect(bufferc(to: channel, from: :ubot).join).to match(/\*Total calls\*: 0\s+/)
    end
    it "excludes routines" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "hi bot", from: user, to: channel
      sleep 0.2
      stats_file = "./spec/bot/stats/#{Dir.children("./spec/bot/stats/")[0]}"
      content = File.read(stats_file).dup
      content.gsub!(",marioruizs,", ",routine/marioruizs,")
      File.open(stats_file, "w") { |file| file.puts content }
      send_message "bot stats exclude routines", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Excluding routines/)
      expect(bufferc(to: channel, from: :ubot).join).not_to match(/\*Total calls\*: 2\s+/)
    end
    it "returns stats for today" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats today", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
      from = to = Time.now.strftime("%Y-%m-%d")
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it "returns stats for yesterday" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats yesterday", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 0\s+/)
      from = to = (Time.now - 86400).strftime("%Y-%m-%d")
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it "returns stats for this week" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats this week", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
      date = Date.today
      wday = date.wday
      wday = 7 if wday == 0
      wday -= 1
      from = "#{(date - wday).strftime("%Y-%m-%d")}"
      to = "#{date.strftime("%Y-%m-%d")}"
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it "returns stats for last week" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats last week", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 0\s+/)
      date = Date.today
      wday = date.wday
      wday = 7 if wday == 0
      wday -= 1
      from = "#{(date - wday - 7).strftime("%Y-%m-%d")}"
      to = "#{(date - wday - 1).strftime("%Y-%m-%d")}"
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it "returns stats for this month" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats this month", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
      date = Date.today
      from = "#{date.strftime("%Y-%m-01")}"
      to = "#{date.strftime("%Y-%m-%d")}"
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it "returns stats for last month" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats last month", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 0\s+/)
      date = Date.today << 1
      from = "#{date.strftime("%Y-%m-01")}"
      to = "#{(Date.new(date.year, date.month, -1)).strftime("%Y-%m-%d")}"
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it "returns stats for this year" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats this year", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
      date = Date.today
      from = "#{date.strftime("%Y-01-01")}"
      to = "#{date.strftime("%Y-%m-%d")}"
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it "returns stats for last year" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats last year", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 0\s+/)
      date = Date.today << 12
      from = "#{date.strftime("%Y-01-01")}"
      to = "#{(Date.new(date.year, 12, -1)).strftime("%Y-%m-%d")}"
      expect(bufferc(to: channel, from: :ubot).join).to match(/from\s+#{from}\s+to\s+#{to}/)
    end

    it 'returns stats for time zones' do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Time\s+Zones\*/i)
      expect(bufferc(to: channel, from: :ubot).join).to match(/Unknown:\s+1\s+\(100\.0%\)/)
    end

    it 'returns stats for job titles' do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Job\s+Titles\*/i)
      expect(bufferc(to: channel, from: :ubot).join).to match(/Unknown:\s+1\s+\(100\.0%\)/)
    end

    it 'returns stats for num users by job title' do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Num\s+Users\s+By\s+Job\s+Title\*/i)
      expect(bufferc(to: channel, from: :ubot).join).to match(/Unknown:\s+1\s+\(100\.0%\)/)
    end  

    #todo: add more tests for options
  end

  describe "on smartbot-stats channel" do
    channel = :cstats
    user = :uadmin

    it "returns stats when master admin" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
    end

    it "returns stats when member" do
      Dir.glob("./spec/bot/stats/*.log").each { |file| File.delete(file) }
      send_message "bot stats", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
    end
  end
end
