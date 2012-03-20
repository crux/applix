$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

#require 'rspec/mocks'
require 'applix'
require 'applix/oattr'

RSpec.configure do |config|
  config.before :each do
  end

  config.after :each do
  end
end
