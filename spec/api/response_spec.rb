require 'spec_helper'

module Epay
  module Api
    describe Response do
      def soap_response(&block)
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct!
        xml.tag! 'soap:Envelope', { 'xmlns:xsi' => 'http://schemas.xmlsoap.org/soap/envelope/',
                                    'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                                    'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/' } do

          xml.tag! 'soap:Body' do
            xml.tag! 'actionResponse' do
              yield xml
            end
          end
        end
        
        xml
      end
      
      let(:response) do
        xml = soap_response do |x|
          x.tag! 'actionResult', 'true'
        end
        
        raw_response = mock('response', :to_s => xml.target!, :code => 200, :headers => {:content_type => 'text/xml'})
        Response.new(raw_response, 'action')
      end
      
      describe "#data" do
        it "returns hash if successful response" do
          response.data.should == {'actionResult' => 'true'}
        end
        
        it "returns string if content-type isn't xml" do
          response.stub(:headers) { {:content_type => 'text/html' }}
          response.data.should be_a String
        end
        
        it "returns string if status code isn't 200" do
          response.stub(:code) { 404 }
          response.data.should be_a String
        end
      end
      
      describe "#success?" do
        it "is true if SOAP action was success" do
          response.success?.should be_true
        end
        
        it "is false when raw_response status code isn't 200" do
          response.raw_response.stub(:code) { 500 }
          response.success?.should be_false
        end
        
        it "is false when soap response is false" do
          xml = soap_response do |x|
            x.tag! 'actionResult', 'false'
          end

          raw_response = mock('response', :to_s => xml.target!, :code => 200, :headers => {:content_type => 'text/xml'})
          response = Response.new(raw_response, 'action')
          
          response.success?.should be_false
        end
      end
    end
  end
end