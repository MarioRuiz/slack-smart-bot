
RSpec.describe SlackSmartBot, "leaderboard" do

  describe "leaderboard" do
    describe "bot channel" do
      channel = :cbot2cu
      it "responds" do
        send_message "leaderboard", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        send_message "ranking", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        send_message "podium", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
      end
      it "returns data for today" do
        send_message "leaderboard today", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`leaderboard`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<#CN1EFTKQB>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*on_bot\*/i)
      end
      it "returns data for yesterday" do
        send_message "leaderboard yesterday", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/No data yet/i)
      end
      it "returns data for last week" do
        send_message "leaderboard last week", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/No data yet/i)
      end
      it "returns data for last month" do
        send_message "leaderboard last month", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/No data yet/i)
      end
      it "returns data for last year" do
        send_message "leaderboard last year", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/No data yet/i)
      end
      it "returns data for this week" do
        send_message "leaderboard this week", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`leaderboard`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<#CN1EFTKQB>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*on_bot\*/i)
      end
      it "returns data for this month" do
        send_message "leaderboard this month", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`leaderboard`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<#CN1EFTKQB>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*on_bot\*/i)
      end
      it "returns data for this year" do
        send_message "leaderboard this year", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`leaderboard`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<#CN1EFTKQB>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*on_bot\*/i)
      end
      it "returns data from YYYY/MM/DD" do
        send_message "leaderboard from 2021/01/01", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`leaderboard`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<#CN1EFTKQB>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*on_bot\*/i)
      end
      it "returns data from YYYY/MM/DD to YYYY/MM/DD" do
        send_message "leaderboard from 2021/01/01 to 2099/01/01", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Leaderboard Smartbot/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`leaderboard`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/<#CN1EFTKQB>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*on_bot\*/i)
      end

    end

  
  end
end
