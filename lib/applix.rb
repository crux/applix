require 'applix/hash'

class Applix 
  def self.main argv, defaults = {}, &blk
    app = Applix.new
    app.instance_eval(&blk)
    app.run(argv, defaults)
  end

  def initialize
  end

  def run argv, defaults
    options = (Hash.from_argv argv)
    options = (defaults.merge options)
    args = options[:args]

    # which task to run depends on first line argument..
    (name = args.shift) or (raise "no task")
    (task = tasks[name.to_sym]) or (raise "no such task: '#{name}' | #{tasks.inspect}")
    task[:code].call(*args, options)
  end

  private 

  def handle name, &blk
    puts "define task: #{name} ==> #{blk}"
    tasks[name.to_sym] = { :code => blk }
  end

  def tasks
    @tasks ||= {}
  end
end

__END__
#
def main args, options = {}
  options = (Defaults.merge options)
  options[:date] = Date.parse(options[:date]) # up-type string date

  action = args.shift or raise "no action"

  # account is an command line arg but password is prompted, never have that in
  # a config or on the command line!
  #
  username = args.shift # or raise "no username"
  password = prompt_for_password

  # which method to run depend on first command line argument..
  send action, username, password, options
end

params = Hash.from_argv ARGV
begin 
  main params[:args], params
rescue => e
  puts <<-EOT

## #{e}

usage: #{__FILE__} <task> <username>

--- #{e.backtrace.join "\n    "}
  EOT
end

__END__

