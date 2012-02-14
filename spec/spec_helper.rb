require 'vcr'
require 'webmock/rspec'

require 'epay'

module Epay
  EXISTING_TRANSACTION_ID     = 8786997
  NON_EXISTING_TRANSACTION_ID = 12345678
end

RSpec.configure do |c|
  c.before(:all) do
    Epay.merchant_number = 8887978
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end