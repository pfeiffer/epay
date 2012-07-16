require 'spec_helper'

module Epay
  describe Transaction do
    let(:transaction) do
      VCR.use_cassette('existing_transaction') do
        Transaction.find(EXISTING_TRANSACTION_ID)
      end
    end
    
    describe "attributes" do
      it "has description" do
        transaction.description.should == "Description of transaction"
      end
      
      it "has amount" do
        transaction.amount.should == 79.0
      end
      
      it "has card" do
        Card.should_receive(:new).with(:number => '333333XXXXXX3000', :exp_year => 12, :exp_month => 10, :kind => :visa)
        transaction.card
      end
      
      it "has group" do
        transaction.group.should == 'Group'
      end
      
      it "has cardholder" do
        transaction.cardholder.should == 'John Doe'
      end
      
      it "has acquirer" do
        transaction.acquirer.should == 'EUROLINE'
      end
      
      it "has currency" do
        transaction.currency.should == :DKK
      end
      
      it "has order no" do
        transaction.order_no.should == 'MY-ORDER-ID'
      end
      
      it "has created_at" do
        transaction.created_at.should == Time.local(2012, 2, 10, 11, 30, 0)
      end
      
      it "has error" do
        transaction.data.stub(:[]).with('error') { 404 }
        transaction.error.should == 404
      end
      
      it "has credited_amount" do
        transaction.credited_amount == 3
      end
    end
    
    describe "#test?" do
      it "is true when mode is EPAY or TEST" do
        transaction.data.stub(:[]).with('mode') { 'MODE_EPAY' }
        transaction.test?.should be_true
        
        transaction.data.stub(:[]).with('mode') { 'MODE_TEST' }
        transaction.test?.should be_true
      end
      
      it "is false when in production" do
        transaction.data.stub(:[]).with('mode') { 'MODE_PRODUCTION' }
        transaction.test?.should be_false
      end
    end
    
    describe "#production?" do
      it "is opposite of test?" do
        transaction.stub(:test?) { false }
        transaction.production?.should be_true
        
        transaction.stub(:test?) { true }
        transaction.production?.should be_false
      end
    end
    
    describe "#captured?" do
      it "is true when captured_at is set" do
        transaction.stub(:captured_at) { Time.now }
        transaction.captured?.should be_true
      end
      
      it "is false when captured_at isn't set" do
        transaction.stub(:captured_at) { nil }
        transaction.captured?.should be_false
      end
    end
    
    describe "#failed?" do
      it "is true when 'failed' is set" do
        transaction.should_not be_failed
        transaction.data.stub(:[]).with('failed') { true }
        transaction.should be_failed
      end
    end
    
    describe "#success?" do
      it "is true unless failed" do
        transaction.stub(:failed?) { false }
        transaction.success?.should be_true
        
        transaction.stub(:failed?) { true }
        transaction.success?.should be_false
      end
    end
    
    describe "#permanent_error?" do
      it "is true unless error code is temporary" do
        transaction.stub(:failed?) { true }
        transaction.stub(:temporary_error?) { false }
        transaction.permanent_error?.should be_true
      end
    end
    
    describe "#temporary_error?" do
      it "is true if error code is a temporary code" do
        transaction.stub(:failed?) { true }
        transaction.stub(:error) { '915' }
        transaction.temporary_error?.should be_true
      end
    end
          
    describe "#capture" do
      it "calls capture action with transaction id and amount in minor" do
        transaction.stub(:amount) { 10 }
        Api.should_receive(:request).with(PAYMENT_SOAP_URL, 'capture', :transactionid => transaction.id, :amount => 1000).and_return(mock('response', :success? => false))
        transaction.capture
      end
      
      context "when request is success" do
        it "reloads and returns true" do
          transaction
          Api.stub(:request).with(PAYMENT_SOAP_URL, 'capture', anything).and_return(mock('response', :success? => true))
          transaction.should_receive(:reload)
          transaction.capture.should be_true
        end
      end
      
      context "when request fails" do
        it "returns false" do
          transaction
          Epay::Api.stub(:request) { mock('response', :success? => false) }
          transaction.capture.should be_false
        end
      end
    end
    
    describe "#credit" do
      context "if amount to be credited is given" do
        it "credits the amount" do
          transaction_id = transaction.id
          Api.should_receive(:request).with(PAYMENT_SOAP_URL, 'credit', :transactionid => transaction_id, :amount => 1000).and_return(mock('response', :success => true))
          transaction.credit(10)
        end
      end
      
      context "with no amount given" do
        it "credits full authorization amount" do
          transaction.stub(:credited_amount) { 10 }
          transaction.stub(:amount) { 60 }
          Api.should_receive(:request).with(PAYMENT_SOAP_URL, 'credit', :transactionid => transaction.id, :amount => 5000).and_return(mock('response', :success => true))
          transaction.credit
        end
      end
    end
    
    describe ".create" do
      context "with valid card data" do
        it "returns transaction" do
          VCR.use_cassette('transaction_creation') do
            transaction = Transaction.create(
              :card_no => '5555555555555000',
              :exp_year => '15',
              :exp_month => '10',
              :cvc => '999',
              :description => 'For the cool products',
              :currency => :DKK,
              :amount => 60,
              :group => 'Test-transactions',
              :cardholder => 'Jack Jensen',
              :order_no => 'TEST-ORDER-12345'
            )
            
            transaction.should be_a Transaction
            transaction.success?.should be_true
            transaction.amount.should == 60
            transaction.cardholder.should == 'Jack Jensen'
          end
        end
      end
      
      context "with invalid card data" do
        it "returns failed transaction" do
          VCR.use_cassette('transaction_invalid_creation') do
            transaction = Transaction.create(
              :card_no => '5555555555555118',
              :exp_year => '15',
              :exp_month => '10',
              :cvc => '999',
              :description => 'For the cool products',
              :currency => :DKK,
              :amount => 60,
              :group => 'Test-transactions',
              :cardholder => 'Jack Jensen',
              :order_no => 'TEST-ORDER-12345'
            )
            
            transaction.should be_a Transaction
            transaction.success?.should be_false
            transaction.amount.should == 60
            transaction.cardholder.should == 'Jack Jensen'
          end
        end
      end
    end
    
    describe ".find" do
      it "returns a transaction" do
        VCR.use_cassette('existing_transaction') do
          Transaction.find(EXISTING_TRANSACTION_ID).should be_a Transaction
        end
      end
    
      it "reloads transaction data" do
        Transaction.any_instance.should_receive(:reload)
        Transaction.find(EXISTING_TRANSACTION_ID)
      end
      
      context "when transaction doesn't exist" do
        it "raises exception" do
          VCR.use_cassette('non_existing_transaction') do
            lambda { Transaction.find(NON_EXISTING_TRANSACTION_ID) }.should raise_error(TransactionNotFound)
          end
        end
      end
    end
  end
end