class SlackSmartBot
  def download_http_content(url, authorizations, team_id_user_creator = nil, session_name = nil)
    begin
      url_message = ""
      parsed_url = URI.parse(url)

      headers = {}

      authorizations.each do |key, value|
        if key.match?(/^(https:\/\/|http:\/\/)?#{parsed_url.host.gsub(".", '\.')}/)
          value.each do |k, v|
            headers[k.to_sym] = v unless k == :host
          end
        end
      end

      extra_message = ""
      domain = "#{parsed_url.scheme}://#{parsed_url.host}"
      if parsed_url.host.match?(/(drive|docs)\.google\.com/) #download the file
        if url.include?("/file/d/")
          gdrive_id = url.split("/d/")[1].split("/")[0]
          url = "https://drive.google.com/uc?id=#{gdrive_id}&export=download"
        end
        io = URI.open(url, headers)
        is_pdf = io.meta["content-type"].to_s == "application/pdf" || io.meta["content-disposition"].to_s.include?("pdf")
        if is_pdf
          require "pdf-reader"
          if io.meta["content-disposition"].to_s.include?("pdf")
            pdf_filename = io.meta["content-disposition"].split("filename=")[1].strip
            extra_message = " PDF file: #{pdf_filename}"
          end
          reader = PDF::Reader.new(io)
          text = reader.pages.map(&:text).join("\n")
        else
          is_docx = io.meta["content-type"].to_s == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" || io.meta["content-disposition"].to_s.include?("docx")
          if is_docx
            require "docx"
            if io.meta["content-disposition"].to_s.include?("docx")
              docx_filename = io.meta["content-disposition"].split("filename=")[1].strip
              extra_message = " DOCX file: #{docx_filename}"
            end
            doc = Docx::Document.open(io)
            text = doc.paragraphs.map(&:to_s).join("\n")
          else #text
            text = io.read
            text_filename = io.meta["content-disposition"].split("filename=")[1].strip if io.meta["content-disposition"].to_s.include?("filename=")
            extra_message = " Text file: #{text_filename}"
          end
        end
        io.close
      elsif parsed_url.path.match?(/\.pdf$/)
        require "pdf-reader"
        io = URI.open(url, headers)
        reader = PDF::Reader.new(io)
        text = reader.pages.map(&:text).join("\n")
        io.close
      elsif parsed_url.path.match?(/\.docx?$/)
        require "docx"
        io = URI.open(url, headers)
        doc = Docx::Document.open(io)
        text = doc.paragraphs.map(&:to_s).join("\n")
        io.close
      else
        parsed_url += "/" if parsed_url.path == ""
        http = NiceHttp.new(host: domain, headers: headers, log: :no)
        path = parsed_url.path
        path += "?#{parsed_url.query}" if parsed_url.query
        response = http.get(path)
        html_doc = Nokogiri::HTML(response.body)
        html_doc.search("script, style").remove
        text = html_doc.text.strip
        text.gsub!(/^\s*$/m, "")
        http.close
      end
      if !session_name.nil? and !team_id_user_creator.nil?
        if (!@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:live_content) or
            @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content].nil? or
            !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content].include?(url)) and
           (!@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:static_content) or
            @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].nil? or
            !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].include?(url))
          url_message = "> #{url}#{extra_message}: content extracted and added to prompt"
        end
      end
    rescue Exception => e
      text = "Error: #{e.message}"
      url_message = "> #{url}: #{text}\n"
    end
    return text, url_message
  end
end
