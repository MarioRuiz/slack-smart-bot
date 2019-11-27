class SlackSmartBot
  def update_bots_file
    file = File.open(config.file_path.gsub(".rb", "_bots.rb"), "w")
    bots_created = @bots_created.dup
    bots_created.each { |k, v| 
      v[:thread] = "" 
    }
    file.write bots_created.inspect
    file.close
  end
end
