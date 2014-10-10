$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

#require 'rspec/mocks'
require 'applix'
require 'applix/oattr'
require 'byebug'

RSpec.configure do |config|
  config.before :each do
  end

  config.after :each do
  end

  # disable $crux debug flag after each test
  config.after(:each) { $crux = false }

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

# captures standard output streams to help testing console I/O
#
def capture(*streams)
  streams.map! { |stream| stream.to_s }
  begin
    result = StringIO.new
    streams.each { |stream| eval "$#{stream} = result" }
    yield
  ensure
    streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
  end
  result.string
end

