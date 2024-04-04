class SlackSmartBot

  #todo: add tests
  def summarize(user, dest, channel, from, thread_ts)
    save_stats(__method__)

    ai_conn, message = SlackSmartBot::AI::OpenAI.connect({}, config, {}, service: :chat_gpt)
    if message.empty?
      ai_models_conn, message = SlackSmartBot::AI::OpenAI.connect({}, config, {}, service: :models)
    end
    if !message.empty? #error connecting
      respond message
    else
      channels_bot_is_in = get_channels(bot_is_in: true)
      if dest[0] == "D" and channel == dest
        respond "Sorry, I can't summarize a direct message. Please use this command in a channel or supply the channel you want to summarize."
      elsif !channels_bot_is_in.id.include?(channel) or !get_channel_members(channel).include?(config.nick_id_granular)
        respond "Sorry, I can't summarize a channel where <@#{config.nick_id_granular}> and <@#{config.nick_id}> are not members. Please invite them to the channel."
      elsif !get_channel_members(channel).include?(user.id)
        respond "Sorry, I can't summarize a channel where you are not a member."
      else
        if (from == "" and channel == dest and Thread.current[:on_thread]) or thread_ts != ""
          summarize_thread = true
          if thread_ts == ""
            thread_ts = Thread.current[:thread_ts]
          else
            if thread_ts.include?(".")
              thread_ts = thread_ts
            else
              thread_ts = thread_ts.scan(/(\d+)/).join
              thread_ts = "#{thread_ts[0..9]}.#{thread_ts[10..-1]}"
            end
          end
        else
          summarize_thread = false
        end
        from_time_off = false
        if from == ""
          from = (Time.now - (60 * 60) * 24 * 30).to_s
          get_vacations()
          if @vacations.key?(user.team_id_user) and @vacations[user.team_id_user].key?(:periods)
            @vacations[user.team_id_user].periods.each do |p|
              #get the last from date
              if p.from > from[0..9].gsub("-", "/")
                from = p.from
                from_time_off = true
              end
            end
            #from will be the day before the last time off
            if from_time_off
              from = (Time.strptime(from, "%Y/%m/%d") - (60 * 60) * 24).to_s
            end
          end
        end

        from.gsub!("-", "/")
        if from.length == 10
          from = from + " 00:00:00"
        elsif from.length == 16
          from = from + ":00"
        end
        from = Time.strptime(from, "%Y/%m/%d %H:%M:%S")
        if summarize_thread
          last_msg = respond("I'm going to summarize the thread messages", return_message: true)
        elsif from_time_off
          last_msg = respond("I'm going to summarize the messages since the day before your last time off #{from.strftime("%Y/%m/%d")} in <##{channel}>. This may take a while.", return_message: true)
        else
          last_msg = respond("I'm going to summarize the messages since #{from.strftime("%Y/%m/%d %H:%M:%S")} in <##{channel}>. This may take a while.", return_message: true)
        end

        @history_still_running ||= false
        if @history_still_running
          respond "Due to Slack API rate limit, `summarize` command is limited. Waiting for other `summarize` command to finish."
          num_times = 0
          while @history_still_running and num_times < 30
            num_times += 1
            sleep 1
          end
          if @history_still_running
            respond "Sorry, Another `summarize` command is still running after 30 seconds. Please try again later."
          end
        end
        unless @history_still_running
          @history_still_running = true
          react :running
          if summarize_thread
            hist = client_granular.conversations_history(channel: channel, oldest: thread_ts, inclusive: true, limit: 1)
          else
            hist = client_granular.conversations_history(channel: channel)
          end
          messages = {} # store the messages by year/month
          act_users = {}
          act_threads = {}
          hist.messages.each do |message|
            if Time.at(message.ts.to_f) >= from or summarize_thread
              year_month = Time.at(message.ts.to_f).strftime("%Y/%m")
              messages[year_month] ||= []
              if message.key?("thread_ts")
                thread_ts_message = message.thread_ts
                replies = client_granular.conversations_replies(channel: channel, ts: thread_ts_message, latest: last_msg.ts)
                sleep 0.5 #to avoid rate limit Tier 3 (50 requests per minute)
                messages_replies = ["Thread Started about last message:"]
                act_threads[message.ts] = replies.messages.size
                replies.messages.each_with_index do |msgrepl, i|
                  act_users[msgrepl.user] ||= 0
                  act_users[msgrepl.user] += 1
                  messages_replies << "<@#{msgrepl.user}> (#{Time.at(msgrepl.ts.to_f)}) wrote:> #{msgrepl.text}" if i > 0
                end
                messages_replies << "Thread ended."
                messages[year_month] += messages_replies.reverse # the order on repls is from older to newer
              end
              act_users[message.user] ||= 0
              act_users[message.user] += 1
              url_to_message = "https://#{client.team.domain}.slack.com/archives/#{channel}/#{message.ts}"
              messages[year_month] << "<@#{message.user}> (#{Time.at(message.ts.to_f)}) (link to the message: #{url_to_message}) wrote:> #{message.text}"
            end
          end
          messages.each do |year_month, msgs|
            messages[year_month] = msgs.reverse # the order on history is from newer to older
          end
          @history_still_running = false
          unreact :running
          if messages.empty?
            respond "There are no Slack Messages since #{from}"
          else
            react :speech_balloon
            chatgpt = ai_conn[user.team_id_user].chat_gpt
            models = ai_models_conn[user.team_id_user].models

            prompt_orig = "Could you please provide a summary of the given conversation, including all key points and supporting details? The summary should be comprehensive and accurately reflect the main message and arguments presented in the original text, while also being concise and easy to understand. To ensure accuracy, please read the text carefully and pay attention to any nuances or complexities in the language. Please also add the most important conversations in the summary. Additionally, the summary should avoid any personal biases or interpretations and remain objective and factual throughout.\n"
            prompt_orig += "If you name an user remember to name it as <@user_id> so it is not replaced by the user name.\n"
            prompt_orig += "Add the link to the message so it is easy to find it. The links added need to follow this <LINK|message>\n"
            prompt_orig += "For example <https://#{client.team.domain}.slack.com/archives/C111JG4V4DZ/1610231016.950299|message>\n"
            prompt_orig += "Add also the date of the message for relevant conversations.\n"
            prompt_orig += "This is the conversation:\n"
            #sort by year/month from older to newer
            messages = messages.sort_by { |k, v| k }.to_h

            @open_ai_model_info ||= {}
            @open_ai_model_info[chatgpt.smartbot_model] ||= SlackSmartBot::AI::OpenAI.models(models.client, models, chatgpt.smartbot_model, return_response: true)
            if @open_ai_model_info[chatgpt.smartbot_model].key?(:max_input_tokens)
              max_num_tokens = @open_ai_model_info[chatgpt.smartbot_model][:max_input_tokens].to_i
            elsif @open_ai_model_info[chatgpt.smartbot_model].key?(:max_tokens)
              max_num_tokens = @open_ai_model_info[chatgpt.smartbot_model][:max_tokens].to_i
            else
              max_num_tokens = 8000
            end
            num_tokens = Tiktoken.encoding_for_model(chatgpt.smartbot_model).encode(prompt_orig + messages.values.flatten.join).length
            respond ":information_source: ChatGPT model: *#{chatgpt.smartbot_model}*. Max tokens: *#{max_num_tokens}*. Characters: #{messages.values.flatten.join.size}. Messages: #{messages.values.flatten.size}. Threads: #{act_threads.size}. Users: #{act_users.size}. Chatgpt tokens: *#{num_tokens}*"

            prompts = []
            i = 0
            messages.each do |year_month, msgs|
              msgs.each do |msg|
                num_tokens = Tiktoken.encoding_for_model(chatgpt.smartbot_model).encode(prompts[i].to_s + msg).length
                i += 1 if num_tokens > max_num_tokens
                prompts[i] ||= prompt_orig
                prompts[i] += "#{msg}\n"
              end
            end
            prompts.each_with_index do |prompt, i|
              num_tokens = Tiktoken.encoding_for_model(chatgpt.smartbot_model).encode(prompt).length #if model != chatgpt.smartbot_model
              respond ":information_source: The total number of chatgpt tokens is more than the max allowed for this chatgpt model. *Part #{i + 1} of #{prompts.size}*.\n" if prompts.size > 1
              success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(chatgpt.client, chatgpt.smartbot_model, prompt, chatgpt)
              result_messages = []
              if success
                result_messages << "*ChatGPT:*\n#{res}"
              else
                result_messages << "*ChatGPT:*\nI'm sorry, I couldn't summarize the conversation. This is the issue: #{res}"
              end
              if i == prompts.size - 1
                act_users.delete(config.nick_id_granular)
                act_users.delete(config.nick_id)

                act_users = act_users.sort_by { |k, v| v }.reverse

                result_messages << "\n\t:runner: Most active users: #{act_users[0..2].map { |k, v| "<@#{k}> (#{v})" }.join(", ")}"
                if act_threads.size > 0 and !summarize_thread
                  act_threads = act_threads.sort_by { |k, v| v }.reverse
                  result_messages << "\t:fire: Most active threads: #{act_threads[0..2].map { |k, v| "<https://#{client.team.domain}.slack.com/archives/#{channel}/#{k}|#{v - 1} replies>" }.join(", ")}"
                end
              end
              respond result_messages.join("\n").gsub("**", "*")
            end
            unreact :speech_balloon
          end
        end
      end
    end
  end
end
