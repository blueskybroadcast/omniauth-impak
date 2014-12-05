require 'omniauth-oauth2'
require 'rest_client'
require 'multi_xml'

module OmniAuth
  module Strategies
    class Nasn < OmniAuth::Strategies::OAuth2
      option :name, 'nasn'

      option :client_options, {
        :user_info_url => 'http://store.atsol.org/ssobsb_Webservices/wsblueskybroadcast.asmx/BlueSkyBroadcastGetUserProfile',
        :authorize_url => 'http://store.atsol.org/ssobsb/sso.aspx'
      }

      uid { raw_info[:id] }

      info do
        {
          :first_name   => raw_info[:first_name],
          :last_name    => raw_info[:last_name],
          :email        => raw_info[:email]
        }
      end

      extra do
        { :raw_info => raw_info }
      end

      def request_phase
        redirect authorize_url
      end

      def callback_phase
        self.access_token = {
          :token =>  request.params['TOKEN'],
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
        RestClient.proxy = proxy_url unless proxy_url.nil?

        response = RestClient.get(user_info_url, params: { token: access_token[:token] })
        response = MultiXml.parse(response)

        info = {
          id: response['BlueSkyBroadcastUserProfile']['CustomerID'],
          first_name: response['BlueSkyBroadcastUserProfile']['FirstName'],
          last_name: response['BlueSkyBroadcastUserProfile']['LastName'],
          email: response['BlueSkyBroadcastUserProfile']['Email']
        }
      end

      private

      def authorize_url
        options.client_options.authorize_url
      end

      def proxy_url
        options.client_options.proxy_url
      end

      def user_info_url
        options.client_options.user_info_url
      end
    end
  end
end
