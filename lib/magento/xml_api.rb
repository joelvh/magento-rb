# Copyright Camptocamp SA 2012
# License: AGPL (GNU Affero General Public License)[http://www.gnu.org/licenses/agpl-3.0.txt]
# Author Guewen Baconnier
#
# https://gist.github.com/1875404
#
# EXAMPLE:
# 
# magento=MagentoAPI.new(ENV['MAGENTO_ENDPOINT'].dup, ENV['MAGENTO_API_USER'].dup, ENV['MAGENTO_API_KEY'].dup, :debug => true)
# order_infos = magento.call('sales_order.info', '100011892')
# 
# magento.call('catalog_product.update', 'SKU', {'meta_description' => 'test'})


require "xmlrpc/client"
require 'pp'

XMLRPC::Config::ENABLE_NIL_PARSER = true

module Magento
  class XmlApi
    
    attr_accessor :url, :api_user, :api_key
    
    def initialize(base_url, api_user, api_key, options={})
      @url = "#{base_url}/api/xmlrpc/"
      @api_user = api_user
      @api_key = api_key
      @timeout = options[:timeout] || 60
      @proxy = options[:proxy] || nil 
      @debug = options[:debug] || false
    end
    
    def call(method, *arguments)
      request('call', session_id, method, arguments)
    end
    
    # def batch(methods)
      # client.multicall
    # end
    
    private
    
    def client
      @client ||= XMLRPC::Client.new2(@url,@proxy,@timeout).tap do |client|
        http_debug(@debug)
        client.set_debug
      end
    end
    
    def http_debug(active)
      output = active ? $stderr : false
        
      XMLRPC::Client.class_eval do
        define_method :set_debug do
          @http.set_debug_output(output)
        end
      end
    end
    
    def session_id
      @session_id ||= request('login', @api_user, @api_key)
    end
    
    def request(method, *arguments)
      begin
        client.call(method, *arguments).tap do |response|
          @retried = false
        end
      rescue EOFError => error
        
        raise error if @retried == true
        
        @retried = true
        request(method, *arguments)
        
      rescue XMLRPC::FaultException => error
        raise Magento::ApiError.new(error.faultString, error.faultCode, error)
      end
    end
    
    def method_missing(method, *args, &block)
      # convert the method name to an XMLRPC action name e.g. "sales_order.list"
      parts = method.to_s.snakecase.split('_')
      action = "#{parts[0..-2].join('_')}.#{parts.last}" if parts.size > 1
      
      if action
        call action, *args, &block
      else
        super
      end
    end
    
  end
end
