module Epay
  module Api
    class Response
      attr_accessor :raw_response, :action
      
      def initialize(raw_response, action)
        @raw_response = raw_response
        @action = action
      end
      
      def success?
        raw_response.code == 200 && data["#{action}Result"] == "true"
      end
      
      def data
        if headers[:content_type] =~ %r(text/xml) && raw_response.code == 200
          # Remove envelope and XML namespace objects
          Hash.from_xml(raw_response.to_s).first.last["Body"]["#{action}Response"].reject { |k,v| k.match(/xmlns/) }
        else
          raw_response.to_s
        end
      end
      
      def method_missing(method, *args)
        raw_response.send(method, *args)
      end
    end
  end
end