RSpec.describe SlackSmartBot, "open_ai_whisper" do
  describe "open_ai whisper" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1
      #todo: add tests when uploading audios
      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
        skip("not wanted to be tested ENV['TEST_ONLY_CHATGPT'].to_s == 'true'") if ENV["TEST_ONLY_CHATGPT"].to_s == "true"
        skip("not added tests for whisper get transcribe")
      end
    end
  end
end
