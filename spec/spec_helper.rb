$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rspec'
require 'applix'
require 'applix/oattr'

Rspec.configure do |config|
  config.mock_with :rspec
end
