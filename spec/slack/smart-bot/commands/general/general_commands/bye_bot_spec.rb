
RSpec.describe SlackSmartBot, "bye_bot" do
  before(:each) do
    salutations = ["example", "<@#{UBOT}>", "bot", "smart"]
    bye = "Bye|Bæ|Good Bye|Adiós|Ciao|Bless|Bless bless|Adeu"
    @bye_bot = "#{bye.split("|").sample} #{salutations.sample}"
    @bye_regexp = /(#{bye})\suser1/i
  end
  it "responds in master channel" do
    send_message @bye_bot, from: :user1, to: :cmaster
    expect(buffer(to: :cmaster, from: :ubot)[0]).to match(@bye_regexp)
  end
  it "responds in direct message" do
    send_message @bye_bot, from: :user1, to: :ubot
    expect(buffer(to: DIRECT.user1.ubot, from: :ubot)[0]).to match(@bye_regexp)
  end
  it "responds in bot channel" do
    send_message @bye_bot, from: :user1, to: :cbot1cm
    expect(buffer(to: :cbot1cm, from: :ubot)[0]).to match(@bye_regexp)
  end

  it 'responds in channel with extended rules' do
    send_message @bye_bot, from: :user1, to: :cext1
    expect(buffer(to: :cext1, from: :ubot)[0]).to match(@bye_regexp)
  end

  it 'responds in private channel with extended rules' do
    send_message @bye_bot, from: :user1, to: :cprivext
    expect(buffer(to: :cprivext, from: :ubot)[0]).to match(@bye_regexp)
  end

  it "resets @answer" do
    send_message "!go to sleep", from: :user1, to: :cbot1cm
    send_message @bye_bot, from: :user1, to: :cbot1cm
    expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to match(@bye_regexp)
    send_message "!which rules", from: :user1, to: :cbot1cm
    expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to match(/bot1cm/)
  end

  it "responds on extended channel" do
    send_message "bye bot", from: :user1, to: :cext1
    expect(buffer(to: :cext1, from: :ubot)[-1]).to match(@bye_regexp)
  end
  describe "on external channel not extended" do
    it "responds" do
      command = "bye bot"
      send_message "#{command}", from: :user1, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot)[0]).to match(@bye_regexp)
  end
  end
end
