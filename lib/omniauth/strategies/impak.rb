require 'omniauth-oauth2'
require 'rest_client'

module OmniAuth
  module Strategies
    class Impak < OmniAuth::Strategies::OAuth2
      option :name, 'impak'

      option :app_options, { app_event_id: nil }

      option :client_options, {
        user_info_url: 'http://portal.nasn.org/Bluesky/service.asmx/Bluesky_Authenticate_NASN_Token',
        authorize_url: 'http://portal.nasn.org/members_online/members/path_login.asp',
        authentication_token: 'MUST BE SET'
      }

      uid { raw_info[:id] }

      info do
        {
          first_name: raw_info[:first_name],
          last_name: raw_info[:last_name],
          email: raw_info[:email],
          is_member: is_member?
        }
      end

      extra do
        { :raw_info => raw_info }
      end

      def request_phase
        slug = session['omniauth.params']['origin'].gsub(/\//,"")
        redirect authorize_url + "?ReturnUrl=" + CGI.escape(callback_url + "?slug=#{slug}")
      end

      def callback_phase
        @app_event = prepare_app_event

        self.access_token = {
          :token =>  request.params['str_token'],
          :token_expires => 60
        }
        puts "!!!! AUTH = #{self.env['omniauth.auth'].inspect}"
        puts "!!!! ORIGIN = #{self.env['omniauth.origin'].inspect}"
        self.env['omniauth.auth'] = auth_hash
        self.env['omniauth.app_event_id'] = @app_event.id
        call_app!
      end

      def creds
        self.access_token
      end

      def auth_hash
        hash = AuthHash.new(:provider => name, :uid => uid)
        hash.info = info
        hash.credentials = creds
        hash.extra = extra
        hash
      end

      def raw_info
        @raw_info ||= get_user_info
      end

      def get_user_info
        request_log = "#{provider_name} Authentication Request:\nGET #{user_info_url}, params: { token: #{access_token[:token]} }"
        @app_event.logs.create(level: 'info', text: request_log)

        begin
          response = RestClient.get(user_info_url, params: { str_token: access_token[:token], str_security_key: authentication_token })
        rescue RestClient::ExceptionWithResponse => e
          error_log = "#{provider_name} Authentication Response Error #{e.message} (code: #{e.response&.code}):\n#{e.response}"
          @app_event.logs.create(level: 'error', text: error_log)
          @app_event.fail!
          return {}
        end

        response_log = "#{provider_name} Authentication Response (code: #{response.code}): \n#{response}"
        @app_event.logs.create(level: 'info', text: response_log)

        response = Nokogiri::XML.parse(response)

        info = {
          id: response.xpath('//status_id').text,
          first_name: response.xpath('//first_name').text,
          last_name: response.xpath('//last_name').text,
          email: response.xpath('//email').text,
          is_member: response.xpath('//isMember').text
        }

        app_event_data = {
          user_info: {
            uid: uid,
            first_name: info[:first_name],
            last_name: info[:last_name],
            email: info[:email]
          }
        }

        @app_event.update(raw_data: app_event_data)

        info
      end

      private

      def authentication_token
        options.client_options.authentication_token
      end

      def authorize_url
        options.client_options.authorize_url
      end

      def is_member?
        raw_info[:is_member] == 'Y'
      end

      def user_info_url
        options.client_options.user_info_url
      end

      def provider_name
        options.name
      end

      def prepare_app_event
        slug = request.params['slug']
        account = Account.find_by(slug: slug)
        account.app_events.where(id: options.app_options.app_event_id).first_or_create(activity_type: 'sso')
      end
    end
  end
end
