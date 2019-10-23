require "spec_helper_settings"

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
  end
  return key
end

def build_DIRECT()
  users = [:uadmin, :user1, :user2]

  http = NiceHttp.new(host: "https://slack.com", headers: { "Authorization" => "Bearer #{ENV["SSB_TOKEN"]}" }, log_headers: :partial)

  users.each do |from|
    users.each do |from|
      DIRECT[from] = {} unless DIRECT.key?(from)
      resp = http.post(path: "/api/im.open", data: { user: get_key(from) })
      DIRECT[from][:ubot] = resp.data.json(:id)
    end
  end
end

build_DIRECT()

def buffer(to:, from:, tries: 20)
  sleep 0.5
  to = get_key(to)
  from = get_key(from)
  found = false
  tries = 0
  result = [""]
  while result == [""] and tries < 20
    sleep 0.2
    b = File.read("./spec/bot/buffer.log")
    result = b.scan(/^|#{to}\|#{from}\|([^\|]+)$/).flatten
    result.delete(nil)
    result.each do |r|
      r.gsub!(/\s*\z/m, "")
    end
    result = [""] if result.to_s == "" or result.empty?
    result = [result] if result.is_a?(String)
    tries += 1
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
  to_key = get_key(to)

  http = NiceHttp.new(host: "https://slack.com", headers: { "Authorization" => "Bearer #{token}" }, log_headers: :partial)

  if to_key[0] == "U" #message from user to user (Direct Message)
    unless DIRECT.key?(from)
      DIRECT[from] = {}
    end

    unless DIRECT[from].key?(to)
      resp = http.post(path: "/api/im.open", data: { user: to_key })
      DIRECT[from][to] = resp.data.json(:id)
    end
    to_key = DIRECT[from][to]
  end

  if file_ruby.to_s == ""
    if SIMULATE
      open("./spec/bot/buffer_complete.log", "a") { |f|
        f.puts "|#{to_key}|#{get_key(from)}|#{message}$$$"
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
  http.close

  sleep ENV["SLEEP_AFTER_SEND"].to_f
end
