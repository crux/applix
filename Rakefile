require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "applix"
    gem.summary = %Q{build typed option hashed from command line arguments}
    gem.description = <<-TXT.gsub /\n\n/, ''
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
         '--txt:\'"foo bar"\'' --> { :txt    => "foo bar" }
         '--txt:%w{foo bar}'   --> { :txt    => ["foo", "bar"] }
         '--now:Time.now'      --> { :now    => #<Date: 3588595/2,0,2299161> }
      
       remaining arguments(non flag/options) are inserted as [:arguments,
       args], eg:
           Hash.from_argv %w(--foo --bar=loo 123 now)
       becomes  
           { :foo => true, :bar => 'loo', :arguments => ["123", "now"] }
      
    TXT
    gem.email = "dirk@sebrink.de"
    gem.homepage = "http://github.com/crux/applix"
    gem.authors = ["dirk luesebrink"]

    gem.add_development_dependency "rspec", ">= 2.3.0"
    gem.add_development_dependency "rcov"
    gem.add_development_dependency "ZenTest", ">= 4.4.2"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require "rspec/core/rake_task"
namespace :test do
  desc "Run all specs."
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.verbose = false
  end

  RSpec::Core::RakeTask.new(:coverage) do |t|
    t.rcov = true
    t.rcov_opts =  %q[--exclude "spec"]
    t.verbose = true
  end
end

task :default => :check_dependencies
task :spec => 'test:spec'

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "applix #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
