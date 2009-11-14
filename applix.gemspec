# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{applix}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["dirk luesebrink"]
  s.date = %q{2009-11-14}
  s.description = %q{      ApplixHash#from_argv builds hashes from ARGV like argument vectors
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
         '--txt:'"foo bar"'' --> { :txt    => "foo bar" }
         '--txt:%w{foo bar}'   --> { :txt    => ["foo", "bar"] }
         '--now:Time.now'      --> { :now    => #<Date: 3588595/2,0,2299161> }
      
       remaining arguments(non flag/options) are inserted as [:arguments,
       args], eg:
           Hash.from_argv %w(--foo --bar=loo 123 now)
       becomes  
           { :foo => true, :bar => 'loo', :arguments => ["123", "now"] }
      
}
  s.email = %q{dirk@sebrink.de}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "applix.gemspec",
     "lib/applix.rb",
     "spec/applix_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/crux/applix}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{build typed option hashed from command line arguments}
  s.test_files = [
    "spec/applix_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
