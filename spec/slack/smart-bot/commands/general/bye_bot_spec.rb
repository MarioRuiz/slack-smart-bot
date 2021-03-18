
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

  it 'doesn\'t responds in channel with extended rules' do
    send_message @bye_bot, from: :user1, to: :cext1
    expect(buffer(to: :cext1, from: :ubot)[0]).not_to match(@bye_regexp)
  end

  it 'doesn\'t responds in private channel with extended rules' do
    send_message @bye_bot, from: :user1, to: :cprivext
    expect(buffer(to: :cprivext, from: :ubot)[0]).not_to match(@bye_regexp)
  end

  it "resets @answer" do
    send_message "!go to sleep", from: :user1, to: :cbot1cm
    send_message @bye_bot, from: :user1, to: :cbot1cm
    expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to match(@bye_regexp)
    send_message "!which rules", from: :user1, to: :cbot1cm
    expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to match(/bot1cm/)
  end

  it "doesn't respond on extended channel" do
    send_message "!bye bot", from: :uadmin, to: :cext1
    expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "bye bot"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
  end
  end
end
