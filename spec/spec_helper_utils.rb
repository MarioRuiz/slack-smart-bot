require_relative "spec_helper_settings"

def get_key(user)
  key = user
  case user.to_sym
  when :ubot
    key = UBOT
  when :ubot2
    key = UBOT2
  when :user1
    key = USER1
  when :user2
    key = USER2
  when :uadmin
    key = UADMIN
  when :cmaster
    key = CMASTER
  when :cbot1cm
    key = CBOT1CM
  when :cbot2cu
    key = CBOT2CU
  when :cexternal
    key = CEXTERNAL
  when :cext1
    key = CEXT1
  when :cpriv1
    key = CPRIV1
  when :cprivext
    key = CPRIVEXT
  when :cstatus 
    key = CSTATUS
  when :cstats
    key = CSTATS
  end
  return key
end

def build_DIRECT()
  users = [:uadmin, :user1, :user2]

  http = NiceHttp.new(host: "https://slack.com", headers: { "Authorization" => "Bearer #{ENV["SSB_TOKEN"]}" }, log_headers: :partial)

  users.each do |from|
    users.each do |from|
      DIRECT[from] = {} unless DIRECT.key?(from)
      resp = http.post(path: "/api/conversations.open", data: { users: get_key(from) })
      DIRECT[from][:ubot] = resp.data.json(:id)
    end
  end
end

build_DIRECT() unless SIMULATE

def buffer(to:, from:, tries: 20, all: false)
  SIMULATE ? sleep(0.2) : sleep(0.5)
  to = get_key(to)
  from = get_key(from)
  found = false
  num = 0
  result = [""]
  while result == [""] and num <= tries
    SIMULATE ? sleep(0.1) : sleep(0.2)
    b = File.read("./spec/bot/buffer.log", encoding: "UTF-8")
    if all
      result = b.scan(/^|#{to}\|#{from}\|(.*)/im).flatten 
    else
      result = b.scan(/^|#{to}\|#{from}\|.*\|([^\|]+)$/).flatten
    end
    result.delete(nil)
    result.each do |r|
      r.gsub!(/\s*\z/m, "")
    end
    result = [""] if result.to_s == "" or result.empty?
    result = [result] if result.is_a?(String)
    num += 1
  end
  return result
end

def bufferc(to:, from:, tries: 20)
  result = buffer(to: to, from: from, tries: tries)
  clean_buffer()
  return result
end

def clean_buffer()
  b = File.read("./spec/bot/buffer.log")
  open("./spec/bot/buffer_copy.log", "a") { |f|
    f.puts b
  }
  File.new("./spec/bot/buffer.log", "w")
end

def send_message(message, from: :ubot, to:, file_ruby: "")
  to_key = get_key(to)
  if SIMULATE
    if to_key[0] == "U" or to_key[0] == "W" #message from user to user (Direct Message)
      to_key = DIRECT[from][to]
    end
  else
    require "nice_http"
    case from
    when :ubot
      token = ENV["SSB_TOKEN"]
    when :ubot2
      token = ENV["SSB_UBOT2"]
    when :user1
      token = ENV["SSB_USER1"]
    when :user2
      token = ENV["SSB_USER2"]
    when :uadmin
      token = ENV["SSB_UADMIN"]
    end

    http = NiceHttp.new(host: "https://slack.com", headers: { "Authorization" => "Bearer #{token}" }, log_headers: :partial)

    if to_key[0] == "U" or to_key[0] == "W" #message from user to user (Direct Message)
      unless DIRECT.key?(from)
        DIRECT[from] = {}
      end

      unless DIRECT[from].key?(to)
        resp = http.post(path: "/api/conversations.open", data: { users: to_key })
        DIRECT[from][to] = resp.data.json(:id)
      end
      to_key = DIRECT[from][to]
    end
  end

  if file_ruby.to_s == ""
    if SIMULATE
      if from.to_s == 'uadmin'
        from_name = 'marioruizs'
      elsif from.to_s == 'user1'
        from_name = 'smartbotuser1'
      elsif from.to_s == 'user2'
        from_name = 'smartbotuser2'
      else
        from_name = from.to_s
      end
      open("./spec/bot/buffer_complete.log", "a") { |f|
        f.puts "|#{to_key}|#{get_key(from)}|#{from_name}|#{message}~~~"
      }
    else
      http.post(path: "/api/chat.postMessage", data: {
        channel: to_key,
        as_user: true,
        text: message,
      })
      sleep 1
    end
  else
    unless SIMULATE
      request = {
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        path: "/api/files.upload",
        data: {
          channels: to_key,
          as_user: true,
          content: file_ruby,
          filename: "example_up.rb",
          initial_comment: message,
        },
      }
      http.post(request)
    end
  end
  http.close unless SIMULATE

  sleep ENV["SLEEP_AFTER_SEND"].to_f
end
