require 'applix/hash'

class Applix 
  def self.main argv, defaults = {}, &blk
    app = Applix.new
    app.instance_eval(&blk)
    app.run(argv, defaults, &blk)
  end

  def self.main! argv, defaults = {}, &blk
    self.main argv, defaults, &blk
  rescue => e
    puts <<-EOT

## #{e}

usage: #{$0} <args...>

--- #{e.backtrace.join "\n    "}
    EOT
  end

  def run argv, defaults
    options = (Hash.from_argv argv)
    options = (defaults.merge options)
    args = (options.delete :args)

    # pre handle, can modify args & options
    @prolog_cb.call(args, options) unless @prolog_cb.nil?


    # logic table for dispatching the command line onto an action
    # 
    # id | name  exits? any | action
    # -- | -----------------+--------------
    #  1 |  -            -  | error: no any, mapped to #3 with name == :any
    #  2 |  -            x  | -> any
    #  3 |  x     -      -  | error: no any
    #  4 |  x     -      x  | -> any
    #  5 |  x     x      -  | -> task
    #  6 |  x     x      x  | -> task
    #
    # having name with no task is the same as no name with no any task..
    name = (args.shift || :any).to_sym
    # shoose existing task or :any
    task = tasks[name] || tasks[:any]
    task or (raise "no such task: '#{name}'")

    # case #4: we must un-shift the name back into the args list to lets any
    # see it as its first argument, 
    (args.unshift name.to_s) if(name != :any && task[:name] == :any)

    # do the call
    rc = task[:code].call(*args, options)

    # post handle
    unless @epilog_cb.nil?
      rc = @epilog_cb.call(rc, args, options)
    end

    rc # return result code from handle callbacks, not the epilog_cb
  end

  private 

  def prolog &blk
    @prolog_cb = blk
  end

  def epilog &blk
    @epilog_cb = blk
  end

  def any &blk
    tasks[:any] = { :name => :any, :code => blk }
  end

  def handle name, &blk
    tasks[name.to_sym] = { :name => name, :code => blk }
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

