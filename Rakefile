require 'rubygems'
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
    gem.add_development_dependency "rspec"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

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
