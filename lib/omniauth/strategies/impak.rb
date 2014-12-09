require 'omniauth-oauth2'
require 'rest_client'
require 'multi_xml'

module OmniAuth
  module Strategies
    class Impak < OmniAuth::Strategies::OAuth2
      option :name, 'impak'

      option :client_options, {
        :user_info_url => 'http://portal.nasn.org/Bluesky/service.asmx/Bluesky_Authenticate_NASN_Token',
        :authorize_url => 'https://portal.nasn.org/members_online/members/path_login.asp'
      }

      uid { raw_info[:id] }

      info do
        {
          :first_name => raw_info[:first_name],
          :last_name => raw_info[:last_name],
          :email => raw_info[:email],
          :is_member => is_member?
        }
      end

      extra do
        { :raw_info => raw_info }
      end

      def request_phase
        slug = session['omniauth.params']['origin'].gsub(/\//,"")
        redirect client.auth_code.authorize_url({"ReturnUrl" => callback_url + "?slug=#{slug}"})
      end

      def callback_phase
        self.access_token = {
          :token =>  request.params['str_token'],
          :token_expires => 60
        }
        self.env['omniauth.auth'] = auth_hash
        self.env['omniauth.origin'] = '/' + request.params['origin']
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
        response = RestClient.get(user_info_url, params: { str_token: access_token[:token], str_security_key: 's5m13@4dl#093n!' })
        response = Nokogiri::XML response

        info = {
          id: response.xpath('//status_id').text,
          first_name: response.xpath('//first_name').text,
          last_name: response.xpath('//last_name').text,
          email: response.xpath('//email').text,
          is_member: response.xpath('//isMember').text
        }
      end

      private

      def authorize_url
        options.client_options.authorize_url
      end

      def is_member?
        raw_info[:is_member] == 'Y'
      end

      def user_info_url
        options.client_options.user_info_url
      end
    end
  end
end