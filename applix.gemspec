# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'applix'
  s.version     = '0.4.3'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['art+com/dirk luesebrink']
  s.email       = ['dirk.luesebrink@artcom.de']
  s.homepage    = 'http://github.com/crux/applix'
  s.summary     = 'extracting typed option hashes from command line arguments'
  s.description = %q{
    ApplixHash#from_argv builds hashes from ARGV like argument vectors
    according to following examples: 
      
         '-f'                  --> { :f      => true }
         '--flag'              --> { :flag   => true }
         '--flag:false'        --> { :flag   => false }
         '--flag=false'        --> { :flag   => 'false' }
         '--option=value'      --> { :option => "value" }
         '--int=1'             --> { :int    => "1" }
         '--float=2.3'         --> { :float  => "2.3" }
         '--float:2.3'         --> { :float  => 2.3 }
         '--txt="foo bar"'     --> { :txt    => "foo bar" }
         '--txt:'"foo bar"''   --> { :txt    => "foo bar" }
         '--txt:%w{foo bar}'   --> { :txt    => ["foo", "bar"] }
         '--now:Time.now'      --> { :now    => #<Date: 3588595/2,0,2299161> }
      
     remaining arguments(non flag/options) are inserted as [:arguments,
     args], eg:
         Hash.from_argv %w(--foo --bar=loo 123 now)
     becomes  
         { :foo => true, :bar => 'loo', :arguments => ["123", "now"] }
  }

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-mocks'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'growl'

  s.add_development_dependency 'ruby-debug19'
  s.add_development_dependency 'ruby-debug-base19'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map do |f| 
    File.basename(f)
  end
  s.require_paths = ["lib"]
end
