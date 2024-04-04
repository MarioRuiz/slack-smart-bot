RSpec.describe SlackSmartBot, "open_ai_edit_image" do
  describe "open_ai edit image" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1
      #todo: add tests when uploading pictures
      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
        skip("not wanted to be tested ENV['TEST_ONLY_CHATGPT'].to_s == 'true'") if ENV['TEST_ONLY_CHATGPT'].to_s == 'true'
        skip("not added tests for edit image")
      end
    end
  end
end
