module Magento
  class SoapApiV2
    extend Savon::Model
    
    def initialize(base_url, api_user, api_key)
      super
      
      @api_user = api_user
      @api_key = api_key
      self.class.client.wsdl.document = "#{base_url}/api/v2_soap?wsdl=1"
    end
    
    def session_id(refresh = false)
      @session_id = nil if refresh
      
      unless @session_id
        response = client.request :login, :body => { :username => @api_user, :apiKey => @api_key }
        @session_id = response[:login_response][:login_return]
      end
      @session_id
    end
    
    def session_request(action, body = {}, &block)
      begin
        # get session ID outside of client#request block because the 
        # request object is a singleton for this client and 
        # the session_id method may have to make a separate request for the ID
        current_session_id = session_id
        
        response = client.request action, :body => body do
          # pass objects to block
          yield soap, wsdl, http, wsse if block
          # add session ID before exiting block
          soap.body ||= {}
          # need to overwrite in case it's an expired session ID
          soap.body[:session] = current_session_id
          soap.body[:order!] = soap.body.keys.delete_if {|item| item == :session }.unshift(:session)
          puts "SOAP BODY:::: #{soap.body}"
        end
        #Savon.config.hooks.select(:model_soap_response).call(response) || response
        # get the response: first child named after the action
        response.to_hash["#{action}_response".to_sym].tap do |response|
          @retries = 0
        end
        
      rescue Savon::SOAP::Fault => error
        # 5 = session expired
        # 2 = access denied
        raise error unless error.to_hash[:fault][:faultcode] == "5" && @retries == 0
        puts "SESSION EXPIRED ... TRYING AGAIN"
        @retries = 1
        # refresh session ID
        session_id(true)
        session_request action, body, &block
      end
      
    end
    
    def end_session
      session_request :end_session
    end
    
    def method_missing(method, *args, &block)
      class_name = self.class.name.snakecase
      action = method
      action = "#{class_name}_#{method}".to_sym unless client.wsdl.soap_actions.include?(action)
      # Magento's actions turn into customer_customer_create, so this allows for customer_create instead
      action = "#{class_name}_#{class_name}_#{method}".to_sym unless client.wsdl.soap_actions.include?(action)
      action = "#{method.to_s.split('_').first}_#{method}".to_sym unless client.wsdl.soap_actions.include?(action)
      puts "SOAP ACTION? #{action}"
      
      if client.wsdl.soap_actions.include?(action)
        body = args.first
        session_request action, body, &block
      else
        super
      end
    end
    
  end
end