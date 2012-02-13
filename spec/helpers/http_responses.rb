module HttpResponses
  def self.included(base) do
    before do
      stub_request(:post, 'https://ssl.ditonlinebetalingssystem.dk/remote/payment.asmx') { 'lol?' }
    end
  end
  
  def stub_soap_request(url, action, parameters)
    Epay::Api.stub(:request).with(url, actions, parameters) do
      
    end
  end
end