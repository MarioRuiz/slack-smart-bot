
RSpec.describe SlackSmartBot, "see_statuses" do
  describe "see statuses" do
    describe "on bot" do
      it "see statuses" do
        send_message "see statuses", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it "see statuses #CHANNEL" do
        send_message "see statuses #bot1cm", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it "see status EMOJI" do
        send_message "see status :boy:", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it "see status EMOJI #CHANNEL" do
        send_message "see status :boy: #bot1cm", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it "see status EMOJI1 EMOJI99" do
        send_message "see status :boy: :palm_tree:", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it "who is on vacation?" do
        send_message "who is on vacation?", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).to match(/\(marioruizs\) on vacation/i)
        expect(buff).to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).not_to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it "who is not on vacation?" do
        send_message "who is not on vacation?", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it "who is not on EMOJI?" do
        send_message "who is not on :palm_tree:", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\) on vacation/i)
        expect(buff).not_to match(/\*Members\* :palm_tree: on <##{CBOT1CM}>/i)
        expect(buff).to match(/\*Members\* :boy: on <##{CBOT1CM}>/i)
      end
      it 'who is available?' do
        send_message "who is available?", from: :user1, to: :cbot1cm
        buff = buffer(to: :cbot1cm, from: :ubot).join
        expect(buff).not_to match(/\(marioruizs\)/i) #it's on vacation
        expect(buff).to match(/\*Available\*\s+\*Members\*\s+:boy:\s+on\s+<##{CBOT1CM}>/i)
        expect(buff).to match(/\(smartbotuser1\)/i)
      end
    end
  end
end
