module Epay
  module Api
    class << self
      def authorize(post)
        # Authorize transaction:
        RestClient.post AUTHORIZE_URL, post do |response|
          # The authorization request redirects to either accept or decline url:
          if location = response.headers[:location]
            query = CGI::parse(URI.parse(location.gsub(' ', '%20')).query)
          
            Hash[query.map do |k, v|
              [k, v.is_a?(Array) && v.size == 1 ? v[0] : v] # make values like ['v'] into 'v'
            end]
          else
            # No location header found
            raise ApiError, response
          end
        end
      end
      
      def default_post_for_params(params)        
        {
          :merchantnumber => Epay.merchant_number,
          
          :cardno     => params[:card_no],
          :cvc        => params[:cvc],
          :expmonth   => params[:exp_month],
          :expyear    => params[:exp_year],
          
          :amount     => (params[:amount] * 100).to_i,
          :currency   => Epay::CURRENCY_CODES[(params[:currency] || Epay.default_currency).to_sym],
          :orderid    => params[:order_no],
          
          :accepturl  => AUTHORIZE_URL + "?accept=1",
          :declineurl => AUTHORIZE_URL + "?decline=1",
        }
      end
      
      def handle_failed_response(response)
        case response.data['epayresponse']
        when "-1002" then raise InvalidMerchantNumber
        when "-1008" then raise TransactionNotFound
        else              raise ApiError, response.data['epayresponse']
        end
      end
      
      def request(url, action, params = {}, &block)
        service_url = "#{url}.asmx"
        soap_action = url + '/' + action
        
        params[:merchantnumber] ||= Epay.merchant_number
        params[:pwd] = Epay.password if Epay.password.present?

        headers = {
          'Content-Type'  => 'text/xml; charset=utf-8',
          'SOAPAction'    => soap_action,
          'User-Agent'    => "Ruby / epay (#{VERSION})"
        }

        # Setup the SOAP body:
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct!
        xml.tag! 'soap:Envelope', { 'xmlns:xsi' => 'http://schemas.xmlsoap.org/soap/envelope/',
                                    'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                                    'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/' } do

          xml.tag! 'soap:Body' do
            xml.tag! action, { 'xmlns' => url } do
              params.each do |attribute, value|
                xml.tag! attribute, value if value.present?
              end
            end
          end
        end
        
        RestClient.post service_url, xml.target!, headers do |raw_response, request, result|
          response = Response.new(raw_response, action)
          
          if block_given?
            yield response
          else
            if response.success?
              return response
            else
              handle_failed_response(response)
            end
          end
        end
      end
    end
  end
end