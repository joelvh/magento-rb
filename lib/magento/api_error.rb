
module Magento
  
  class ApiError < StandardError
    attr_reader :message, :error_code, :original_exception

    def initialize(message, error_code = nil, original_exception = nil)
      @message = message
      @error_code = error_code
      @original_exception = original_exception
    end
    
    def to_s
      "#{message} (error code: #{error_code})"
    end
  end

end