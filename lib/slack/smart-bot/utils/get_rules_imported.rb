class SlackSmartBot

  def get_rules_imported
    if File.exist?("#{config.path}/rules/rules_imported.rb")
      if !defined?(@datetime_rules_imported) or @datetime_rules_imported != File.mtime("#{config.path}/rules/rules_imported.rb")        
        @datetime_rules_imported = File.mtime("#{config.path}/rules/rules_imported.rb")
        file_conf = IO.readlines("#{config.path}/rules/rules_imported.rb").join
        unless file_conf.to_s() == ""
          @rules_imported = eval(file_conf)
        end
      end
    end
  end
  
end
