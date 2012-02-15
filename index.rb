## ePay
# The `epay` gem gives you a convenient wrapper for the ePay payment gateway.

### Installation

# Just install the gem:
gem install epay
# or add to your Gemfile:
gem 'epay' 

### Setup

# Require the epay gem in your code and set your merchant number:
require 'epay'
Epay.merchant_number = 88776655

# If you've entered an API password in the ePay administration interface, set it as well:
Epay.password = 'my_pass'

# If can set a default currency to avoid having to explicitly pass `:currency` argument on each authorization:
Epay.default_currency = :DKK

### Transactions
# The gem gives you access to the `Transaction` model, which you can use to create and manipulate transactions.

#### Authorize a new transaction using card data

# Use `.create` to authorize a new transaction:
@transaction = Epay::Transaction.create(
  :card_no => '3330333333333000',
  :exp_year => 14,
  :exp_month => 10,
  :cvc => '999',
  :amount => 150.0,
  :order_no => 'AWESOME-INC-12346',
# Optional parameters :
  :description => 'My awesome transaction',
  :group => 'Awesome transactions',
  :cardholder => 'Jack Doe'
)
=> #<Epay::Transaction id: 1234, ...>

# The transaction object gives you various details about the transaction:

@transaction.success?
=> true

@transaction.amount
=> 150.0

#### Find transaction

# Use `.find` to look up a specific transaction:
@transaction = Epay::Transaction.find(1234567)
=> #<Epay::Transaction id: 1234567, ...>

#### Capture a transaction

# Just call `capture` on the transaction:
@transaction.capture
=> true

@transaction.captured?
=> true

#### Delete transaction

# Use `delete` to delete a transaction:
@transaction.delete
=> true

@transaction.deleted?
=> true


#### Credit a transaction

# Use `credit` to credit a captured transaction. If no amount if given the full transaction amount is credited:
@transaction.credit(10)
=> true

@transaction.credited_amount
=> 10.0

# Credit the remaining part of transaction:
@transaction.credit
=> true