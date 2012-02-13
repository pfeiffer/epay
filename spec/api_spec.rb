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
          before do
            @parsed_body = Nokogiri::XML(@body)
          end
          
          it "has merchant number" do
            pending
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