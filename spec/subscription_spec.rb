require 'spec_helper'

module Epay
  describe Subscription do
    let(:subscription) do
      VCR.use_cassette('existing_subscription') do
        Subscription.find(387544)
      end
    end
    
    describe "attributes" do
      it "has created_at" do
        subscription.created_at.should == Time.new(2012, 2, 9, 12, 11)
      end
      
      it "has description" do
        subscription.description.should == "Test-subscriber"
      end
    end
    
    describe "#transactions" do
      it "returns a list of transactions" do
        subscription.transactions.should be_a Enumerable
        subscription.transactions.first.should be_a Transaction
      end
      
      context "when no transactions has been made" do
        it "returns an empty list" do
          subscription.data.delete('transactionList')
          subscription.transactions.should == []
        end
      end
    end
    
    describe "#card" do
      it "returns card" do
        Card.should_receive(:new).with(:exp_year => 12, :exp_month => 10, :kind => :visa, :number => '333333XXXXXX3000')
        subscription.card
      end
      
      context "when no transaction has been made" do
        it "doesn't set number on card" do
          subscription.stub(:transactions) { [] }
          Card.should_receive(:new).with(:exp_year => 12, :exp_month => 10, :kind => :visa)
          subscription.card
        end
      end
    end
    
    describe ".all" do
      it "returns a list of subscriptions" do
        VCR.use_cassette('subscriptions') do
          subscriptions = Subscription.all
          subscriptions.should be_a Enumerable
          subscriptions.first.should be_a Subscription
        end
      end
    end
    
    describe "#delete" do
      it "requests to api" do
        subscription_id = subscription.id
        
        Api.should_receive(:request).with(SUBSCRIPTION_SOAP_URL, 'delete', :subscriptionid => subscription_id) {
          mock(Api::Response, :success? => true)
        }
        
        subscription.delete
      end
    end
    
    describe ".create" do
      it "creates a new subscription" do
        VCR.use_cassette('subscription_creation') do
          subscription = Subscription.create(:card_no => '5555555555555000', :exp_year => '15', :exp_month => '10', :cvc => '999', :description => 'A new subscriber', :currency => :DKK)
          subscription.should be_a Subscription
          subscription.transactions.should be_empty
        end
      end
      
      context "when card data is invalid" do
        describe "the returned subscription" do
          let(:subscription) do
            VCR.use_cassette('subscription_invalid_creation') do
              Subscription.create(:card_no => '5555555555555118', :exp_year => '15', :exp_month => '10', :cvc => '999', :description => 'A new subscriber', :currency => :DKK)
            end
          end
          
          it "has error code" do
            subscription.error.should == '118'
          end
          
          it "is isn't valid" do
            subscription.should_not be_valid
          end
        end
      end
    end
    
    describe "#authorize" do
      it "returns new transaction" do
        VCR.use_cassette('subscription_authorization') do
          transaction = subscription.authorize(:order_no => 'NEW ORDER', :amount => 10.0, :currency => :DKK)
          transaction.should be_a Transaction
        end
      end
      
      context "when authorization fails" do
        it "returns transaction with error code etc." do
          subscription
          
          response = mock(Api::Response)
          response.stub(:success?) { false }
          response.stub(:data) { {'pbsresponse' => '404'} }
          
          Api.stub(:request).with(SUBSCRIPTION_SOAP_URL, 'authorize', anything).and_yield(response)
          
          Transaction.should_receive(:new).with(nil, 'ErrorCode' => '404')
          subscription.authorize(:order_no => 'NEW ORDER', :amount => 10.0, :currency => :DKK)
        end
      end
    end
  end
end