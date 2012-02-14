require 'spec_helper'
require 'nokogiri'

module Epay
  describe Api do
    describe ".authorize" do
      it "hits the authorize endpoint" do
        RestClient.should_receive(:post).with(Epay::AUTHORIZE_URL, anything)
        Api.authorize(:amount => 10)
      end
    end
    
    describe ".request" do
      before do
        RestClient.stub(:post) { |url, body, headers| @url = url; @body = body; @headers = headers }
        Api.request('https://ssl.ditonlinebetalingssystem.dk/remote/payment', 'gettransaction', :transactionid => 42)
      end
      
      describe "the request" do
        it "has content-type xml" do
          @headers['Content-Type'].should =~ /text\/xml/
        end
      
        it "has SOAPAction header" do
          @headers['SOAPAction'].should == 'https://ssl.ditonlinebetalingssystem.dk/remote/payment/gettransaction'
        end
        
        context "body" do
          def body_to_xml(body)
            Nokogiri::XML(body).remove_namespaces!
          end
          
          it "has merchant number" do
            body_to_xml(@body).xpath('//merchantnumber/child::text()').to_s.should == Epay.merchant_number.to_s
          end
          
          it "is adds parameters" do
            xml = body_to_xml(@body)
            xml.xpath('//Envelope/Body/gettransaction/transactionid/child::text()').to_s.should == "42"
          end
          
          context "if password is set" do
            it "adds pwd field" do
              Epay.password = 'password_for_api'
              Api.request('https://ssl.ditonlinebetalingssystem.dk/remote/payment', 'gettransaction', :transactionid => 42)
              body_to_xml(@body).xpath('//pwd/child::text()').to_s.should == 'password_for_api'
            end
          end
        end
      end
      
      it "posts to endpoint" do
        RestClient.should_receive(:post).with('https://ssl.ditonlinebetalingssystem.dk/remote/payment.asmx', anything, anything)
        Api.request('https://ssl.ditonlinebetalingssystem.dk/remote/payment', 'gettransaction', :transactionid => 42)
      end
    end
  end
end