# frozen_string_literal: true

require_relative 'feed_into/version'
require_relative './modules/general.rb'

require 'nokogiri'
require 'net/http'
require 'time'
require 'tzinfo'
require 'active_support/core_ext/hash/indifferent_access'

#require 'active_support/core_ext/hash'
require 'cgi'
require 'json'
require 'rss'

module FeedInto
  class Error < StandardError; end


  class Single
    SINGLE = {
      format: {
        title: {
          symbol: {
            video: '👾',
            custom: '⚙️ ',
            web: '🤖'
          },
          separator: '|',
          more: '...',
          length: 100,
          str: '{{sym}} {{cmd_name__upcase}} ({{channel_name__upcase}}) {{separator}} {{title_item__titleize}}'
        },
        download: {
          agent: ''
        }
      },
      validation: {
        allows: [
          :format__title__symbol__video,
          :format__title__symbol__custom,
          :format__title__symbol__web,
          :format__title__separator,
          :format__title__more,
          :format__title__length,
          :format__title__str,
          :format__download__agent,
        ],
        wildcards: [
          :options__s3
        ]
      },
      channels: [],
      options: {}
    }

    attr_reader :settings
    include General


    def initialize( modules: nil, options: {} )
      mdl = modules.class.eql? String
      chn = options.keys.include? :channels
      mode = :not_found

      if !mdl and !chn
        puts 'No Channel found.'
      else
        mode = nil

        if chn
          mode = :options
          transfer = Marshal.load( Marshal.dump( options[:channels] ) )
          options.delete( :channels )
        end

        mdl ? mode = :folder : ''

        @single = Marshal.load( Marshal.dump( SINGLE ) )
        if options_update( options, @single, true )
          @single[:channels].concat( crl_general_channels() )

          chn ? @single[:channels].concat( transfer ) : ''
          mdl ? @single[:channels].concat( load_modules( modules ) ) : ''

          @single = options_update( options, @single, false )
          @settings = @single
        else
        end
      end
    end

    
    def analyse( item: {}, trust_item: false )
      def modul( type, channel, allow_methods, cmd, response, data, obj )
        messages = []
        if !channel[ type ].nil?
          error = nil
          execute = true
          name = nil
          case channel[ type ]
            when :self
              name = ( 'crl_' + channel[:name].to_s ).to_sym
              !allow_methods.include?( name ) ? execute = false : ''
            when :general
              name = :crl_general
          else
            name = :crl_general
            type = ( type.to_s + '_' + channel[ type ].to_s ).to_sym
          end

          if execute
            data, messages = self
              .method( name )
              .call( type, cmd, channel, response, data, obj )
          else
            messages = [ "Modul: #{name} not found." ]
          end
        else
        end

        return data, messages
      end


      def formats( type, cmd, channel, response, data, obj )
        channel[ type ].each do | format_ |
          data = self
            .method( 'crl_general' )
            .call( format_, cmd, channel, response, data, obj )[ 0 ]
        end
        return data
      end


      def set_status( messages )
        s = 'Download: Status '
        status = nil

        if messages.class.eql? Array
          tmp = messages
            .find { | a | a.start_with?( s ) }
            .to_s
            .gsub( s, '')
            .to_i
          tmp.nil? ? status = 0 : status = tmp
        else
        end

        return status
      end


      result = {
        cmd: nil,
        result: nil,
        messages: nil,
        time: nil,
        success: false,
        status: nil
      }

      obj = Marshal.load( Marshal.dump( @single ) )

      begin
        start = Time.now.to_f
        messages = []
        status = nil
        cmd = {}
        data = nil

        if trust_item
          cmd, m0 = item[:cmd], item[:messages]
        else
          cmd, m0 = cmd( item, obj )
        end

        messages.concat( m0 )
        if cmd[:valid]
          channel = obj[:channels].find { | c | c[:name].eql? cmd[:channel] }
          allow_channels = obj[:channels].map { | a | ( 'crl_' + a[:name].to_s ).to_sym }
          allow_methods = self.methods.select { | a | allow_channels.include?( a.to_sym ) }

          response, m1 = modul( :download, channel, allow_methods, cmd, response, nil, obj )
          messages.concat( m1 )

          data, m2 = modul( :mining, channel, allow_methods, cmd, response, nil, obj )
          messages.concat( m2 )

          data = formats( :pre, cmd, channel, response, data, obj )

          data, m3 = modul( :transform, channel, allow_methods, cmd, response, data, obj )
          messages.concat( m3 )

          data = formats( :post, cmd, channel, response, data, obj )
          result[:success] = true
        end

        result[:cmd] = cmd
        result[:result] = data 
        result[:messages] = messages
        result[:time] = Time.now.to_f - start

        status = set_status( messages )
        result[:status] = status

      rescue => e
        messages.push( "Begin/Rescue: #{e}" )

        result[:cmd] = cmd
        result[:result] = data 
        result[:messages] = messages
        result[:time] = Time.now.to_f - start

        status = set_status( messages )
        result[:status] = status
      end

      return result
    end


    def cmd( cmd, obj )
      def validate( cmd )
        check = {
          validation: {
            struct: false,
            url: false,
            channel: false,
          },
          struct: {
            name: String,
            url: String,
            category: Symbol,
            channel: Symbol
          }
        }

        messages = []

        check[:validation][:struct] = check[:struct]
          .map { | k, v | cmd[ k ].class.eql? v } 
          .all?

        !check[:validation][:struct] ? messages.push( 'Structure of cmd is not valid.' ) : ''

        if cmd[:url] =~ URI::regexp
          check[:validation][:url] = true
        else
          messages.push( "'#{cmd[:url]}' is not a valid URL.")
        end

        if !cmd[:channel].eql? :not_found
          check[:validation][:channel] = true
        else
          messages.push( 'Channel not found' )
        end

        cmd[:valid] = check[:validation].map { | k, v | v }.all?

        return cmd, messages
      end


      if [ Hash, ActiveSupport::HashWithIndifferentAccess ].include? cmd.class
        !cmd.key?( :name ) ? cmd[:name] = 'Unknown' : ''
        !cmd.key?( :category ) ? cmd[:category] = :unknown : ''
        cmd[:category].class.eql?( String ) ? cmd[:category] = cmd[:category].to_s.downcase.to_sym : ''
      else
        if cmd.class.eql? String
          cmd = {
            name: 'Unknown',
            url: cmd,
            category: :unknown,
            #channel: :not_found
          }
        else
          cmd = {
            name: 'Invalid',
            url: cmd.to_s,
            category: :invalid,
            channel: :not_found
          }
        end
      end

      f = obj[:channels].find do | channel | 
        r = channel[:regexs]
          .map { | ps | ps.map { | p | cmd[:url].match?( p ) }.all? }
          .include?( true )
      end

      !f.nil? ? cmd[:channel] = f[:name] : cmd[:channel] = :not_found

      valid, messages = validate( cmd )

      return valid, messages
    end


    private


    def load_modules( folder )
      mods = []
      searchs = []

      Dir[ folder + '*.*' ].each do | path |
        #require_relative path
        require path

        search = open( path ).read.split( "\n" )
          .find { | a | a.include?( 'module' ) }
          .gsub('module ', '' )

        searchs.push( search )
      end

      searchs.each do | search |
        name = Module::const_get( search )
        extend name
      end

      names = self.methods
        .select { | a | a.to_s.start_with?( 'crl' ) }
        .reject { | a | a.eql? ( ( 'crl_general' ).to_sym ) }

      channels = []
      names.each do | n |
        mods.push( n.to_s.gsub( 'crl_', '' ) )
        channel, messages = self
          .method( n.to_sym )
          .call( :settings, nil, nil, nil, nil, nil )
        channels.push( channel )
      end

      puts "#{mods.length} Module#{mods.length > 2 ? 's' : ''} loaded (#{mods.join(', ')})"
      return channels
    end


    def options_update( options, obj, validation )
      def str_difference( a, b )
        a = a.to_s.downcase.split( '_' ).join( '' )
        b = b.to_s.downcase.split( '_' ).join( '' )
        longer = [ a.size, b.size ].max
        same = a
          .each_char
          .zip( b.each_char )
          .select { | a, b | a == b }
          .size
        ( longer - same ) / a.size.to_f
      end
    
    
      allows = obj[:validation][:allows]
      wildcards = obj[:validation][:wildcards]
    
      messages = []
      insert = Marshal.load( Marshal.dump( obj ) )
    
      options.keys.each do | key |
        if allows.include?( key ) 
    
          keys = key.to_s.split( '__' ).map { | a | a.to_sym }
          case( keys.length )
            when 1
              insert[ keys[ 0 ] ] = options[ key ]
            when 2
              insert[ keys[ 0 ] ][ keys[ 1 ] ] = options[ key ]
            when 3
              insert[ keys[ 0 ] ][ keys[ 1 ] ][ keys[ 2 ] ] = options[ key ]
            when 4
              insert[ keys[ 0 ] ][ keys[ 1 ] ][ keys[ 2 ] ][ keys[ 3 ] ] = options[ key ]
          end
        else 
          standard = true
          keys = key.to_s.split( '__' ).map { | a | a.to_sym }
          case keys.length
            when 1
              inside = wildcards
                .map { | a | a.to_s.split( '__' ).first.to_sym }
                .include?( keys[ 0 ] )
    
              if inside
                message = "\"#{key}\" is a potential Wildcard key but has an invalid length. Use two additional keys (plus '__') to set your option."
                messages.push( message )
                standard = false
              else
              end
            when 2..3
              wildcard = [ keys[ 0 ].to_s, keys[ 1 ].to_s ].join( '__' ).to_sym
              if wildcards.include?( wildcard )
                if keys.length == 2
                  message = "\"#{key}\" is a Wildcard key but has an invalid length. Use an additional key (plus '__') to set your option."
                  messages.push( message )
                  standard = false
                else
                  !insert.keys.include?( keys[ 0 ] ) ? insert[ keys[ 0 ] ] = {} : ''
                  !insert[ keys[ 0 ] ].keys.include?( keys[ 1 ] ) ? insert[ keys[ 0 ] ][ keys[ 1 ] ] = {} : ''
                  insert[ keys[ 0 ] ][ keys[ 1 ] ][ keys[ 2 ] ] = options[ key ]
                  standard = false
                end
              else
              end
          else
          end
    
          if standard
            nearest = allows
              .map { | word | { score: self.str_difference( key, word ), word: word } }
              .min_by { | item | item[:score] }

            if nearest.nil?
              message =  "\"#{key}\" is not a valid key."
            else
              message = "\"#{key}\" is not a valid key, did you mean \"<--similar-->\"?"
              message = message.gsub( '<--similar-->', nearest[:word].to_s )
            end

            messages.push( message )
          end
        end
      end
    
      if messages.length != 0
        messages.length == 1 ? puts( 'Error found:' ) : puts( 'Errors found:' ) 
        messages.each { | m | puts( '- ' + m ) }
      end
      return validation ? messages.length == 0 : insert
    end
  end


  class Group < Single
    GROUP= {
      meta: {
        timestamp: nil
      },
      validation: {
        allows: [
          :sleep__range,
          :sleep__codes,
          :sleep__varieties,
          :sleep__scores__ok__name,
          :sleep__scores__ok__value,
          :sleep__scores__user__name,
          :sleep__scores__user__value,
          :sleep__scores__server__name,
          :sleep__scores__server__value,
          :sleep__scores__other__name,
          :sleep__scores__other__value,
          :sleep__stages
        ],
        wildcards: []
      },
      sleep: {
        range: 15,
        codes: [
          {
            status: 0,
            name: 'other',
            add: :user           
          },
          {
            status: 100,
            name: 'continue',
            add: :server
          },
          {
            status: 101,
            name: 'switching_protocols',
            add: :server
          },
          {
            status: 200,
            name: 'ok',
            add: :ok
          },
          {
            status: 201,
            name: 'created',
            add: :ok
          },
          {
            status: 202,
            name: 'accepted',
            add: :ok
          },
          {
            status: 203,
            name: 'non_authoritative_information',
            add: :ok
          },
          {
            status: 204,
            name: 'no_content',
            add: :ok
          },
          {
            status: 205,
            name: 'reset_content',
            add: :ok
          },
          {
            status: 206,
            name: 'partial_content',
            add: :ok
          },
          {
            status: 207,
            name: 'multi_status',
            add: :ok
          },
          {
            status: 208,
            name: 'already_reported',
            add: :ok
          },
          {
            status: 226,
            name: 'im_used',
            add: :ok
          },
          {
            status: 300,
            name: 'multiple_choices',
            add: :user
          },
          {
            status: 301,
            name: 'moved_permanently',
            add: :user
          },
          {
            status: 302,
            name: 'found',
            add: :user
          },
          {
            status: 303,
            name: 'see_other',
            add: :user
          },
          {
            status: 304,
            name: 'not_modified',
            add: :user
          },
          {
            status: 305,
            name: 'use_proxy',
            add: :user
          },
          {
            status: 306,
            name: 'switch_proxy',
            add: :user
          },
          {
            status: 307,
            name: 'temporary_redirect',
            add: :user
          },
          {
            status: 308,
            name: 'permanent_redirect',
            add: :user
          },
          {
            status: 400,
            name: 'bad_request',
            add: :user
          },
          {
            status: 401,
            name: 'unauthorized',
            add: :server
          },
          {
            status: 402,
            name: 'payment_required',
            add: :server
          },
          {
            status: 403,
            name: 'forbidden',
            add: :server
          },
          {
            status: 404,
            name: 'not_found',
            add: :user
          },
          {
            status: 405,
            name: 'method_not_allowed',
            add: :server
          },
          {
            status: 406,
            name: 'not_acceptable',
            add: :server
          },
          {
            status: 407,
            name: 'proxy_authentication_required',
            add: :server
          },
          {
            status: 408,
            name: 'request_timeout',
            add: :user
          },
          {
            status: 409,
            name: 'conflict',
            add: :server
          },
          {
            status: 410,
            name: 'gone',
            add: :user
          },
          {
            status: 411,
            name: 'length_required',
            add: :user
          },
          {
            status: 412,
            name: 'precondition_failed',
            add: :user
          },
          {
            status: 413,
            name: 'request_entity_too_large',
            add: :user
          },
          {
            status: 414,
            name: 'request_uri_too_long',
            add: :user
          },
          {
            status: 415,
            name: 'unsupported_media_type',
            add: :server
          },
          {
            status: 416,
            name: 'requested_range_not_satisfiable',
            add: :user
          },
          {
            status: 417,
            name: 'expectation_failed',
            add: :user
          },
          {
            status: 418,
            name: 'im_a_teapot',
            add: :server
          },
          {
            status: 421,
            name: 'misdirected_request',
            add: :server
          },
          {
            status: 422,
            name: 'unprocessable_entity',
            add: :server
          },
          {
            status: 426,
            name: 'upgrade_required',
            add: :server
          },
          {
            status: 428,
            name: 'precondition_required',
            add: :server
          },
          {
            status: 423,
            name: 'locked',
            add: :server
          },
          {
            status: 424,
            name: 'failed_dependency',
            add: :server
          },
          {
            status: 429,
            name: 'too_many_requests',
            add: :server
          },
          {
            status: 431,
            name: 'request_header_fields_too_large',
            add: :user
          },
          {
            status: 451,
            name: 'unavailable_for_legal_reasons',
            add: :server
          },
          {
            status: 500,
            name: 'internal_server_error',
            add: :server
          },
          {
            status: 501,
            name: 'not_implemented',
            add: :server
          },
          {
            status: 502,
            name: 'bad_gateway',
            add: :server
          },
          {
            status: 503,
            name: 'service_unavailable',
            add: :server
          },
          {
            status: 504,
            name: 'gateway_timeout',
            add: :server
          },
          {
            status: 505,
            name: 'http_version_not_supported',
            add: :server
          },
          {
            status: 506,
            name: 'variant_also_negotiates',
            add: :server
          },
          {
            status: 507,
            name: 'insufficient_storage',
            add: :server
          },
          {
            status: 508,
            name: 'loop_detected',
            add: :server
          },
          {
            status: 510,
            name: 'not_extended',
            add: :server
          },
          {
            status: 511,
            name: 'network_authentication_required',
            add: :server
          }
        ],
        varieties: [
          { variety: 1, sleep: 2 },
          { variety: 2, sleep: 1 },
          { variety: 3, sleep: 0.5 },
          { variety: 4, sleep: 0.25 },
          { variety: 5, sleep: 0.15 },
          { variety: 6, sleep: 0.1 }
        ],
        scores: {
          ok: {
            name: 'Went through...',
            value: 0
          },
          user: {
            name: 'Wrong query, Data not found...',
            value: 1
          },
          server: {
            name: 'Wrong behavour, not patient enough...',
            value: 3
          },
          other: {
            name: 'Nil values and others errors...',
            value: 0
          }
        },
        stages: [
          {
            name: 'Default',
            range: [ 0, 2 ],
            skip: false,
            sleep: 0
          },
          {
            name: 'Low',
            range: [ 3, 5 ],
            skip: false,
            sleep: 2
          },
          {
            name: 'High',
            range: [ 6, 8 ],
            skip: false,
            sleep: 5
          },
          {
            name: 'Stop',
            range: [ 9, 999 ],
            skip: true
          }
        ]
      },
      options: {}
    }


    def initialize( modules: nil, group: {}, single: {} )
      mdl = modules.class.eql? String
      chn = single.keys.include? :channels
      mode = :not_found

      if !mdl and !chn
        puts 'No Channel found.'
      else
        if chn
         # mode = :options
         # transfer = Marshal.load( Marshal.dump( options[:channels] ) )
         # options.delete( :channels )
        end

        @group = Marshal.load( Marshal.dump( GROUP ) )
        @group[:meta][:timestamp] = Time.now.utc.to_s
        
        if options_update( group, @group, true )
          @single = Single.new( modules: modules, options: single )
          @group = options_update( group, @group, false )
          @analyse = nil
          @merge = nil
        else
        end
      end
    end


    def analyse( items: nil, silent: false )
      def c_log( silent, r, score )
        if !silent
          print "(#{score[:sleep]})  "
          if r[:success] 
            if r[:result][:items].length > 0
              r[:success] ? print( r[:result][:items][ 0 ][:title] ) : ''
            else
              print r[:result][:meta][:title]
            end
          else
            print r[:cmd][:name]
            r[:messages].each { | m | puts( "- #{m}" ) }
          end
          puts
        else
        end
      end


      cmds, messages = cmds( items )

      if cmds[:valid]
        keys = cmds[:cmds]
          .map { | a | a[:cmd][:channel] }
          .to_set
          .to_a
        
        groups = keys.inject( {} ) do | hash, key |  
          hash[ key ] = cmds[:cmds].select { | cmd | cmd[:cmd][:channel].eql?( key ) } 
          hash
        end

        orders, struct = get_shuffle( groups )
        results = struct.inject( {} ) do | item, k | 
          item[ k[ 0 ] ] = {}
          item[ k[ 0 ] ][:responses] = k[ 1 ].clone
          item[ k[ 0 ] ][:status] = k[ 1 ].clone
          item
        end

        orders.each.with_index do | order, index |
          start = Time.now.to_f
          score = score( index, orders, results, @group, groups )
          cmd = groups[ order[:category] ][ order[:index ] ]

          if score[:skip]
            !silent ? puts( ">> Skip: #{order}" ) : ''
            results[ order[:category] ][:responses][ order[:index] ] = {
              cmd: cmd[:cmd],
              skip: true
            }
          else
            sleep( score[:sleep] )
            r = @single.analyse( item: cmd, trust_item: true )

            !r[:status].class.eql? Integer ? tmp = 0 : tmp = r[:status]
            results[ order[:category] ][:status][ order[:index] ] = tmp #r[:status]
            results[ order[:category] ][:responses][ order[:index] ] = r
            results[ order[:category] ][:responses][ order[:index] ][:skip] = false 

            results[ order[:category] ][:responses][ order[:index] ][:time] = Time.now.to_f - start
            c_log( silent, r, score )
          end

        end
      else
        puts 'cmds not valid.'
        messages.each { | m | puts( "- #{m}" ) }
      end


      items = results
        .map { | k, v | v[:responses].map { | a | a } }
        .flatten

      categories = items
        .map { | item | item[:cmd][:category] }
        .to_set
        .to_a

      re_grouped = categories
        .inject( {} ) { | group, category | 
          group[ category] = items.select { | a | a[:cmd][:category].eql? category }
          group
        }

      @analyse = re_grouped
      self
    end


    def merge
      def valid?( item ) 
        result = false

        if [ Hash, ActiveSupport::HashWithIndifferentAccess ].include? item.class
          one = [ :title, :time, :url ]
            .map { | key | item.keys.include? key }
            .all?

          if one
            if [ Hash, ActiveSupport::HashWithIndifferentAccess ].include? item[:time].class
              if item[:time].keys.include? :stamp
                result = true
              end
            end
          end
        end

        return result
      end


      messages = []
      result = @analyse.inject( {} ) do | categories, d |
        all = d[ 1 ].inject( [] ) do | category, response |
          if response[:skip]
          else
            if response[:success]
              response[:result][:items].each do | item |
                if valid?( item )
                  itm = {
                    title: item[:title],
                    timestamp: item[:time][:stamp],
                    url: item[:url]
                  }
        
                  category.push( itm )
                else
                  messages.push( '- One or more key(s) in Item are not available.' )
                end
              end
            end
          end
          category
        end

        all = all.sort_by { | a | -a[:timestamp] }
        categories[ d[ 0 ].to_sym ] = all.clone
        categories
      end

      messages.each { | message | puts( message ) }

      @merge = result
      self
    end


    def to_h( type: nil )
      if @analyse.nil? and @merge.nil?
        puts 'No Data found, please use .analyse() before.'
        return nil
      else
        if type.nil?
          if @merge.nil?
            return @analyse
          else
            return @merge
          end
        else
          case type
            when :merge
              return @merge
            when :analyse
              return @analyse
          end
        end
      end
    end


    def to_rss( key: Symbol, silent: false )
      result = ''

      if @merge.nil?
        !silent ? puts( 'Data is not merged in groups, use .merge() before.' ) : ''
      else
        if @merge.keys.include? key
          rss = RSS::Maker.make( 'atom' ) do | maker |
            maker.channel.author = ''
            maker.channel.updated = Time.now.to_s
            maker.channel.about = ''
            maker.channel.title = key.to_s
      
            @merge[ key ].each do | entry |
              maker.items.new_item do | item |
                item.link = entry[:url]
                item.title = entry[:title]

                d = Time.at( entry[:timestamp] ).to_datetime.to_s

                item.updated = d
              end   
            end
          end
        else
          !silent ? puts( 'Key does not exist.' ) : ''
        end
        result = rss.to_s.gsub( '<link href="', '<link rel="alternate" href="' )
      end

      return result
    end


    def to_rss_all( silent: false )
      results = {}

      if @merge.nil?
        !silent ? puts( 'Data is not merged in groups, use .merge() before.' ) : ''
      else
        @merge.keys.each do | key |
          results[ key ] = to_rss( key: key, silent: false )
        end
      end

      return results
    end


    def status( silent: false )
      def categories( analyse )
        results = {}
         analyse.keys.each do | key |
          a = {
            status: {
              success: nil,
              error: nil,
              skip: nil,
              total: nil
            },
            errors: nil,
            time: nil
          }
          
          a[:status][:success] = analyse[ key ]
            .reject { | a | a[:skip] }
            .select { | a | a[:success].eql? true }
            .length

          a[:status][:error] = analyse[ key ]
            .reject { | a | a[:skip] }
            .select { | a | a[:success].eql? false }
            .length
          
          a[:status][:skip] = analyse[ key ]
            .select { | a | a[:skip] }
            .length

          a[:status][:total] = [ :success, :error, :skip ]
            .map { | key | a[:status][ key ] }
            .sum
          
          a[:errors] = analyse[ key ]
            .reject { | a | a[:skip] }
            .select { | a | a[:success].eql? false }
            .map { | a | { name: a[:cmd][:name], url: a[:cmd][:url] } }
          
          a[:time] = analyse[ key ]
            .reject { | a | a[:skip] }
            .map { | a | a[:time] }
            .sum
            .round( 8 )
      
          results[ key ] = a
        end
        results
      end
      
      
      def channels( analyse )
        results = {}
        
        channels = analyse
          .map { | category |
            category[ 1 ]
              .map { | a | a[:cmd][:channel] }
          }
          .flatten
          .to_set
          .to_a
        
        channels.each do | channel |
          a = {
            status: {
              success: nil,
              error: nil,
              skip: nil,
              total: nil
            },
            errors: nil,
            time: nil
          }
          
          cmds = analyse
            .map { | category |
              category[ 1 ]
                .select { | a | a[:cmd][:channel].eql? channel }
            }
            .flatten
                    
          a[:status][:success] = cmds
            .reject { | a | a[:skip] }
            .select { | a | a[:success] }
            .length
          
          a[:status][:error] = cmds
            .reject { | a | a[:skip] }
            .select { | a | !a[:success] }
            .length
          
          a[:status][:skip] = cmds
            .select { | a | a[:skip] }
            .length
          
          a[:status][:total] = [ :success, :error, :skip ]
            .map { | key | a[:status][ key ] }
            .sum
          
          a[:time] = cmds
            .map { | a | a.keys.include?( :time ) ?  a[:time] : 0 }
            .sum
            .round( 8 )
          
          a[:errors] = cmds
            .reject { | a | a[:skip] }
            .select { | a | !a[:success] }
            .map { | a | { name: a[:cmd][:name], url: a[:cmd][:url] } }
            
          results[ channel ] = a
        end
        
        return results
      end
      
      
      def overview( channels ) 
        results = { time: {}, all: {} }
        results[:time][:now] = Time.now.utc.to_s
        z = channels
          .keys
          .map { | key | channels[ key ][:time] }
          .sum
          .round( 0 )
        
        results[:time][:analyse] = 
          Time.at( z ).utc.strftime( "%Mm %Ss" )
        
        [ :success, :error, :skip, :total ].each do | key | 
          results[:all][ key ] = channels
            .map { | k, v | v[:status][ key ] }
            .sum
        end
        return results
      end
      
      
      if @analyse.nil?
        !silent ? puts( 'Data is not analysed, use .analyse() before.' ) : ''
      else
        
        messages = {
          overview: {},
          channels: {},
          categories: {}
        }

        messages[:categories] = categories( @analyse )
        messages[:channels] = channels( @analyse )
        messages[:overview] = overview( messages[:channels] )
      end

      return messages
    end


    private


    def cmds( cs )
      valid = {
        array: true,
        hash: true,
      }

      result = {
        valid: false,
        cmds: []
      }

      cmds = []
      messages = []
      if cs.class.eql? Array
        test = cs.map do | c |
          [ Hash, ActiveSupport::HashWithIndifferentAccess, String ].include? c.class
        end

        if test.all?
          cmds = cs.map do | c |
            cmd, messages = @single.cmd( c, @single.settings )
            { cmd: cmd, messages: messages }
          end
        else
          valid[:hash] = false
          messages.push( 'cmds: Not all Items are Class "Hash"' )
        end
      else
        valid[:array] = false
        messages.push( 'cmds: Input is not Class "Array"' )
      end

      result[:valid] = valid.map { | k, v | v }.all?
      result[:cmds].concat( cmds )

      return result, messages
    end


    def get_shuffle( groups )
      def struct( groups )
        boilerplate = groups
          .inject( {} ) { | hash, k | hash[ k[ 0 ] ] = k[ 1 ].length; hash }

        struct = boilerplate.inject( {} )  do | hash, key |
          hash[ key[ 0 ] ] = key[ 1 ].times.map { | a | nil }
          hash
        end
        
        groups = boilerplate.inject( {} )  do | hash, key |
          hash[ key[ 0 ] ] = key[ 1 ].times.map { | a | "#{key[ 0 ]}--#{a}" }
          hash
        end
    
        return groups, struct
      end
  

      def shuffle( struct, groups )
        results = []
        order = []

        l = struct.map { | k, v | v.length }.sum
        for round in 0..l - 1
          selections = struct
            .filter_map { | k, v | k if v.length > 0 }

          variety = selections.length
          if round == 0
            current = selections[ 0 ]
          else
            case selections.length
              when 0
                before = 0
              when 1
                before = 0
              when 2
                before = 1
              when 3
                before = 2
              when 4
                before = 3
            else
              before = 4
            end

            selections = selections
              .reject { | s | order.last( before ).include?( s ) }      
          end

          current = selections[ rand( 0..selections.length - 1 ) ]
          r_index = rand( 0..struct[ current ].length - 1 )

          index = struct[ current ][ r_index ].split( '--' ).last.to_i

          channel = groups[ current ][ index ][:cmd][:channel]

          result = { category: current, index: index, variety: variety, channel: channel }

          results.push( result )

          struct[ current ].delete_at( r_index )
          order.push( current )
        end

        return results
      end
      
      tmp, struct = struct( groups )
      orders = shuffle( tmp, groups )
      #orders.each { | order | puts( order.to_s ) }

      return orders, struct
    end


    def score( index, orders, results, obj, groups )
      current = orders[ index ]

      if index == 0
        test = []
      else
        test = orders
          .first( index )
          .select { | order | order[:channel].eql? current[:channel] }
         
        test = test
          .map { | cmd | 
            if results[ cmd[:category] ][:responses][ cmd[:index] ][:skip]
              :skip
            else
              results[ cmd[:category] ][:responses][ cmd[:index] ][:status]
            end
          }
          .select { | a | !a.eql?( :skip ) }
          .last( obj[:sleep][:range] )
      end

      scores = test.map do | sr |
        if sr.nil?
          key = :other
        else
          tmp = obj[:sleep][:codes].find { | a | a[:status].eql?( sr ) }
          key = tmp[:add]
        end
        obj[:sleep][:scores][ key ][:value]
      end

      score = scores.sum
      tmp = obj[:sleep][:stages].find do | a |
        case a[:range].length
          when 1
            score >= a[:range][ 0 ]
          when 2
            score >= a[:range][ 0 ] and score <= a[:range][ 1 ]
        end
      end
      result = Marshal.load( Marshal.dump( tmp ) )

      found = obj[:sleep][:varieties]
        .find { | variety | variety[:variety].eql? current[:variety] }

      tension = !found.nil? ? found[:sleep] : 0 
      result[:sleep] = result[:sleep].to_i + tension.to_i

      result[:score] = score
      return result
    end
  end
end
