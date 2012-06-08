require "magento/soap_api_v2"
require "magento/xml_api"

module Magento
  
  def self.api_endpoint=(value)
    @api_endpoint = value
  end
  
  def self.api_username=(value)
    @api_username = value
  end
  
  def self.api_password=(value)
    @api_password = value
  end
  
  def self.debug=(value)
    @debug = value
  end
  
  debug = false
  
  def self.xml_api
    @client ||= XmlApi.new @api_endpoint, @api_username, @api_password, :debug => @debug
  end
  
  def self.soap_api
    @client ||= SoapApiV2.new @api_endpoint, @api_username, @api_password
  end
  
end