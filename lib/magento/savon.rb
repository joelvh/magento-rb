#
# Magento API can be found @ http://www.magentocommerce.com/wiki/doc/webservices-api/api
#
#
require 'savon'
 
Savon.configure do |config|
  config.log = false            # disable logging
  #config.log_level = :info      # changing the log level
  #config.logger = Rails.logger  # using the Rails logger
end
 
client = Savon::Client.new do
  wsdl.document = "#{ENV['MAGENTO_ENDPOINT']}/index.php/api/?wsdl"
end
 
response = client.request :login do
  soap.body = { :username => ENV['MAGENTO_API_USER'], :apiKey => ENV['MAGENTO_API_KEY'] }
end

if response.success? == false
  puts "login failed"
  #System.exit(0)
end
 
session =  response[:login_response][:login_return];
 
response = client.request :call do
  soap.body = {:session => session, :method => 'catalog_product_attribute_media.list', :sku => '001' }
end
 
# fetching all products
if response.success?
  # listing found products
  response[:call_response][:call_return][:item][:item].each do |product|
    puts "-------------------------------------------"
    #product = product[:item]
    product.each do |pkey|
        puts "#{pkey}"
    end
  end
end
 
#logging out
response = client.request :endSession do
  soap.body = {:session => session}
end
puts response.to_hash