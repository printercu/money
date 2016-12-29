if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

spec_path = File.dirname(__FILE__)
$LOAD_PATH.unshift(spec_path)

require 'rspec'
require 'rspec/its'
require 'i18n/core_ext/hash'
require 'pry'
Dir[Pathname(spec_path).join('support/**/*.rb')].each { |f| require f }

require 'money'

I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.order = :random
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.include MoneySpecHelpers
end

BigDecimal.class_eval do
  def inspect
    "#<BigDecimal #{to_s('F')}>"
  end
end
