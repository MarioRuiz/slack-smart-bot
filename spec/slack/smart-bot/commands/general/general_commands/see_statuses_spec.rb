
RSpec.describe SlackSmartBot, "see_statuses" do
  describe "see statuses" do
    describe "on bot" do
      channel = :cbot2cu
      channel_name = "bot2cu"
      channel_id = CBOT2CU
      it "see statuses" do
        send_message "see statuses", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it "see statuses #CHANNEL" do
        send_message "see statuses ##{channel_name}", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it "see status EMOJI" do
        send_message "see status :boy:", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it "see status EMOJI #CHANNEL" do
        send_message "see status :boy: ##{channel_name}", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it "see status EMOJI1 EMOJI99" do
        send_message "see status :boy: :palm_tree:", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it "who is on vacation?" do
        send_message "who is on vacation?", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).not_to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it "who is not on vacation?" do
        send_message "who is not on vacation?", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it "who is not on EMOJI?" do
        send_message "who is not on :palm_tree:", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{channel_id}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{channel_id}>/i)
      end
      it 'who is available?' do
        send_message "who is available?", from: :user1, to: channel
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\)/i) #it's on vacation
        expect(buff).to match(/\*Available\*\s+\*Members\*\s+:boy:\s+on\s+<##{channel_id}>/i)
        expect(buff).to match(/\(smartbotuser1\)/i)
      end
    end
  end
end
