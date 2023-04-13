module General
    def crl_general( sym, cmd, channel, response, data, obj, custom={} )
      messages = []
  
      case sym
        when :download
          result, messages = crl_general_download( cmd[:url], obj )
        when :pre_titles
          result, messages = crl_general_pre_titles( cmd, channel, data, obj )
        when :mining_rss_one
          result = crl_general_mining_rss_one( cmd[:url], response, obj )
        when :mining_rss_two
          result = crl_general_mining_rss_two( cmd[:url], response, obj )
        when :format_url_s3
          result = crl_general_format_url_s3( obj, channel[:options][:html], custom[:query] )
        when :format_html_remove
          result = crl_general_format_html_remove( custom[:html] )
      else
        messages.push( "General: #{sym} not found." )
      end
  
      return result, messages
    end
  
  
    private
  
  
    def crl_general_channels()
      return []
    end
  
  
    def crl_general_download( url, obj )
      version = ( rand( 89.0..91.0 ) + ( rand( 530.0..540.0 ) / 1000 ) ).round( 2 ) 
      agent = obj[:format][:download][:agent].gsub( '{{version}}', version.to_s )
      uri = URI( url )

      header = {}
      header['User-Agent'] = agent
      header['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      header['Accept-Language'] = 'en-US,en;q=0.5'
      header['Connection'] = 'keep-alive'
      header['Upgrade-Insecure-Requests'] = '1'
      header['Sec-Fetch-Dest'] = 'document'
      header['Sec-Fetch-Mode'] = 'navigate'
      header['Sec-Fetch-Site'] = 'none'
      header['Sec-Fetch-User'] = '?1'
      header['Pragma'] = 'no-cache'
      header['Cache-Control'] = 'no-cache'

      response = Net::HTTP.get_response( uri, header )
      return response.body, [ "Download: Status #{response.code}" ]
    end
    
    
    def crl_general_mining_rss_one( url, response, obj )
      doc = Nokogiri::XML( response )
  
      feed = {
          meta: {
            title: nil,
            url: nil
          },
          items: []
      }
  
      feed[:meta][:title] = doc.at( 'title' ).text.gsub( '"',"'" )
      feed[:meta][:url] = url
  
      entries = doc.css( 'item' )
      entries.each do | entry | 
        item = {
          title: nil,
          time: {
            stamp: nil,
            utc: nil
          }
        }
  
        tmp = entry.at( 'title' ).text
        item[:title] = self
          .method( 'crl_general' )
          .call( :format_html_remove, nil, nil, nil, nil, nil, { html: tmp } )[ 0 ]
  
        item[:title_viewer] = item[:title]
        item[:time][:stamp] = Time.parse( entry.at( 'pubDate' ) ).to_i
        item[:time][:utc] = entry.at( 'pubDate' ).text
        item[:url] = entry.at( 'link' ).text
  
        feed[:items].push( item )
      end
  
      return feed
    end
    
    
    def crl_general_mining_rss_two( url, response, obj )
      doc = Nokogiri::XML( response )
  
      feed = {
          meta: {
            title: nil,
            url: nil
          },
          items: []
      }
  
      feed[:meta][:title] = doc.at( 'title' ).text.gsub( '"',"'" )
      feed[:meta][:url] = url
  
      entries = doc.css( 'entry' )
      entries.each do | entry | 
        item = {
          title: nil,
          time: {
            stamp: nil,
            utc: nil
          }
        }
  
        tmp = entry.at( 'title' ).text
        item[:title] = self
          .method( 'crl_general' )
          .call( :format_html_remove, nil, nil, nil, nil, nil, { html: tmp } )[ 0 ]
  
        item[:title_viewer] = item[:title]
        item[:time][:stamp] = Time.parse( entry.at( 'updated' ) ).to_i
        item[:time][:utc] = entry.at( 'updated' ).text
        item[:url] = entry.at( 'link' ).attribute('href').value
  
        feed[:items].push( item )
      end
  
      return feed
    end
    
    
    def crl_general_format_url_s3( obj, file, query )
      result = ''
      result << 'https://'
      result << obj[:options][:s3][:bucket_name]
      result << '.s3.'
      result << obj[:options][:s3][:region]
      result << '.amazonaws.com/'
      result << obj[:options][:s3][:bucket_sub_folder]
      result << obj[:options][:s3][:bucket_folder]
      result << file
      result << '?'
      result << URI.encode_www_form( query )
  
      return result
    end
    
    
    def crl_general_format_html_remove( html )
  
      result = ''
      Nokogiri::HTML( CGI.unescapeHTML( html.to_s ) ).traverse do | e |
        result << e.text if e.text?
      end
  
      result = result
        .strip
        .split( ' ' )
        .map{ | word | word.capitalize }
        .join( ' ' )
  
      return result
    end
    
  
    def crl_general_pre_titles( cmd, channel, data, obj )
      messages = []
  
      data[:items].map.with_index do | item, index |
        title, errors = crl_general_pre_title( cmd, channel, data, index, obj )
        messages.concat( errors )
        item[:title] = title
      end
      
      return data, messages
    end
    
    
    def crl_general_pre_title( cmd, channel, data, d_index, obj )
      messages = []
      str = obj[:format][:title][:str]
  
      parts = str
        .scan( /\{{[a-z,_,:]+\}}/ )
        .map { | match | 
          {
            gsub: match,
            cmd: match.gsub( /[{:}]/, '' )
          }
        }
  
      parts.each do | part |
        text = part[:cmd].to_sym
        formats = []
        
        if !part[:cmd].index( '__' ).nil?
          tmp = part[:cmd].split( '__' )
          formats = tmp.last.split( '_' ).map { | a | a.to_sym }
          text = tmp[ 0 ].to_sym
        end
  
        case text
          when :cmd_name
            insert = cmd[:name].dup.to_s
          when :channel_name
            insert = channel[:name].dup.to_s.gsub( '_', ' ' )
          when :sym
            insert = obj[:format][:title][:symbol][ channel[:sym] ].dup
          when :separator
            insert = obj[:format][:title][:separator].dup
          when :title_channel
            insert = channel[:name].dup
          when :title_item
            insert = data[:items][ d_index ][:title].dup
          when :title_meta
            insert = data[:meta][:title].dup
        else
          messages.push( "Set Title (insert): #{text} not found." )
        end
  
        formats.each do | f |
          case f
            when :upcase
              f.eql?( :upcase ) ? insert.upcase! : ''
            when :titleize
              insert = insert
                .split( ' ' )
                .map { | word | word.capitalize }
                .join( ' ' )
          else
            messages.push( "Set Title (format): #{text} not found." )
          end
        end
        str = str.gsub( part[:gsub], insert )
      end
  
      if str.length > obj[:format][:title][:length]
        str = str[ 0, obj[:format][:title][:length] ] + obj[:format][:title][:more]
      end
  
      return str, messages
    end
  end