
RSpec.describe SlackSmartBot, "bot_status" do
  it "responds in master channel to admin user" do
    send_message "bot status", from: :uadmin, to: :cmaster
    sleep 10
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/ping from bot1cm/)
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/ping from bot2cu/)
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/Rules file: smart-bot-example_rules.rb/)
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/`bot1cm` \(#{CBOT1CM}\):/)
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/`bot2cu` \(#{CBOT2CU}\):/)
  end
  it "responds in master channel to admin user on bot1cm" do
    send_message "bot status", from: :user1, to: :cmaster
    sleep 10
    expect(buffer(to: :cmaster, from: :ubot).join).not_to match(/ping from bot1cm/)
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/ping from bot2cu/) # user1 is admin of bot2cu
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/Rules file: smart-bot-example_rules.rb/)
    expect(buffer(to: :cmaster, from: :ubot).join).not_to match(/`bot1cm` \(#{CBOT1CM}\):/)
    expect(buffer(to: :cmaster, from: :ubot).join).not_to match(/`bot2cu` \(#{CBOT2CU}\):/)
  end
  it "responds in master channel to normal user" do
    send_message "bot status", from: :user2, to: :cmaster
    sleep 10
    expect(buffer(to: :cmaster, from: :ubot).join).not_to match(/ping from bot1cm/)
    expect(buffer(to: :cmaster, from: :ubot).join).not_to match(/ping from bot2cu/)
    expect(buffer(to: :cmaster, from: :ubot).join).to match(/Rules file: smart-bot-example_rules.rb/)
    expect(buffer(to: :cmaster, from: :ubot).join).not_to match(/`bot1cm` \(#{CBOT1CM}\):/)
    expect(buffer(to: :cmaster, from: :ubot).join).not_to match(/`bot2cu` \(#{CBOT2CU}\):/)
  end

  it "responds in bot channel" do
    send_message "bot status", from: :user1, to: :cbot1cm
    sleep 3
    expect(buffer(to: :cbot1cm, from: :ubot).join).not_to match(/ping from bot1cm/)
    expect(buffer(to: :cbot1cm, from: :ubot).join).not_to match(/ping from bot2cu/)
    expect(buffer(to: :cbot1cm, from: :ubot).join).to match(/Rules file: slack-smart-bot_rules_#{CBOT1CM}_#{UADMIN_NAME}.rb/)
    expect(buffer(to: :cbot1cm, from: :ubot).join).not_to match(/`bot1cm` \(#{CBOT1CM}\):/)
    expect(buffer(to: :cbot1cm, from: :ubot).join).not_to match(/`bot2cu` \(#{CBOT2CU}\):/)
  end

  it "doesn't respond on extended channel" do
    send_message "!bot status", from: :uadmin, to: :cext1
    expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
  end

  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "bot status"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end
