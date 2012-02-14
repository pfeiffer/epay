module Epay
  class Transaction
    include Model
    
    def self.inspectable_attributes
      %w(id amount created_at order_no description cardholder acquirer currency group captured)
    end
    
    def amount
      data['authamount'].to_f / 100
    end
    
    def created_at
      return nil if failed?
      Time.parse(data['authdate'])
    end
    
    def order_no
      data['orderid']
    end
    
    def currency
      Epay::CURRENCY_CODES.key(data['currency'])
    end
    
    def description
      data['description']
    end
    
    def cardholder
      data['cardholder']
    end
    
    def acquirer
      data['acquirer']
    end
    
    def group
      data['group']
    end
    
    def card
      # We can find some card data in the history:
      @card ||= Card.new(:kind => CARD_KINDS[data['cardtypeid'].to_i], :number => data['tcardno'], :exp_year => data['expyear'].to_i, :exp_month => data['expmonth'].to_i)
    end
    
    def credited_amount
      data['creditedamount'].to_f / 100
    end
    
    def captured_amount
      data['capturedamount'].to_f / 100
    end
    
    def captured_at
      return nil if failed?
      
      time = Time.parse(data['captureddate'].to_s)
      time < created_at ? nil : time
    end
    
    def captured
      !captured_at.nil?
    end
    alias_method :captured?, :captured
    
    def success?
      !failed?
    end
    
    def failed?
      !!data['failed']
    end
    
    def error
      data['error']
    end
    
    def test?
      data['mode'] == 'MODE_EPAY' || data['mode'] == 'MODE_TEST'
    end
    
    def production?
      !test?
    end
    
    # Actions
    def reload
      response = Epay::Api.request(PAYMENT_SOAP_URL, 'gettransaction', :transactionid => id)
      @data = response.data['transactionInformation']
      self
    end
    
    def capture
      response = Epay::Api.request(PAYMENT_SOAP_URL, 'capture', :transactionid => id, :amount => (amount * 100).to_i)
      if response.success?
        reload
        true
      else
        false
      end
    end
    
    def credit(amount_to_be_credited = nil)
      amount_to_be_credited ||= amount - credited_amount
      
      Epay::Api.request(PAYMENT_SOAP_URL, 'credit', :transactionid => id, :amount => amount_to_be_credited * 100) do |response|
        if response.success?
          true
        else
          raise TransactionInGracePeriod if response.data['epayresponse'] == "-1021"
          
          false
        end
      end
    end
    
    def delete
      Epay::Api.request(PAYMENT_SOAP_URL, 'delete', :transactionid => id).success?
    end
    
    # ClassMethods
    class << self
      def find(id)
        transaction = new(id)
        transaction.reload
      end
      
      # Epay::Transaction.create(:card_no => '12345', :cvc => '123', :exp_month => '11', :exp_year => '12', :amount => '119', :order_no => 'ND-TEST')
      
      def create(params)
        post = Api.default_post_for_params(params).merge({
          :orderid        => params[:order_no],
          :amount         => params[:amount]*100,
          :currency       => Epay::CURRENCY_CODES[(params[:currency] || Epay.default_currency).to_sym],
          :description    => params[:description],
          :cardholder     => params[:cardholder],
          :group          => params[:group],
          :instantcapture => params[:instant_capture] ? '1' : '0'
        })
        
        query = Api.authorize(post)
        
        if query['accept']
          # Find the transaction
          transaction = Transaction.find(query["tid"].to_i)
        else
          # Return a new transaction with error code filled
          new(nil, {
            'failed'      => true,
            'error'       => query["error"],
            'orderid'     => post[:orderid],
            'authamount'  => post[:amount],
            'description' => post[:description],
            'cardholder'  => post[:cardholder],
            'group'       => post[:group],
            'currency'    => post[:currency]
          })
        end
      end
    end
  end
end