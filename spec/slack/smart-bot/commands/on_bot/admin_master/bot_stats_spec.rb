
RSpec.describe SlackSmartBot, "bot_stats" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :uadmin

      it "is not allowed" do
        send_message "!bot stats", from: user, to: channel
        message = "Only Master admin users on a private conversation with the bot can see the bot stats"
        expect(buffer(to: channel, from: :ubot).join).to match(/#{message}/)
      end
    end
  
    describe "on master channel" do
      channel = :cmaster
      user = :uadmin
  
      it "is not allowed" do
        send_message "!bot stats", from: user, to: channel
        message = "Only Master admin users on a private conversation with the bot can see the bot stats"
        expect(buffer(to: channel, from: :ubot).join).to match(/#{message}/)
      end
    end

    describe "on extended channel" do
      it "is not allowed" do
        send_message "!bot stats'", from: :uadmin, to: :cext1
        message = "I don't understand"
        expect(buffer(to: :cext1, from: :ubot).join).to match(/#{message}/)
      end
    end
  
    describe "on external channel not extended" do
      it "is not allowed" do
        command = '!bot stats'
        send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
        expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
      end
    end
    
    describe "on direct message" do
      channel = DIRECT.uadmin.ubot
      user = :uadmin

      it "is not allowed if not user admin" do
        send_message "!bot stats'", from: :user1, to: DIRECT.user1.ubot
        message = "Only Master admin users on a private conversation with the bot can see the bot stats"
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/#{message}/)
      end
      
      it "returns stats" do
        Dir.glob("./spec/bot/stats/*.log").each {|file| File.delete(file)}
        send_message "bot stats", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/\*Total calls\*: 1\s+/)
      end
      it 'excludes master admins' do
        Dir.glob("./spec/bot/stats/*.log").each {|file| File.delete(file)}
        send_message "hi bot", from: user, to: channel
        send_message "bot stats exclude masters", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Excluding master admins/)
        expect(bufferc(to: channel, from: :ubot).join).to match(/\*Total calls\*: 0\s+/)
      end
      it 'excludes routines' do
        Dir.glob("./spec/bot/stats/*.log").each {|file| File.delete(file)}
        send_message "hi bot", from: user, to: channel
        sleep 0.2
        stats_file = "./spec/bot/stats/#{Dir.children('./spec/bot/stats/')[0]}"
        content = File.read(stats_file).dup
        content.gsub!(',marioruizs,',',routine/marioruizs,')
        File.open(stats_file, "w") {|file| file.puts content }
        send_message "bot stats exclude routines", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Excluding routines/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/\*Total calls\*: 2\s+/)
      end
      
      #todo: add more tests for options
    end
  
  end
  