require 'applix/hash'

class Applix 
  def self.main argv, defaults = {}, &blk
    app = Applix.new
    app.instance_eval(&blk)
    app.run(argv, defaults)

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

    # pre handle
    @prolog_cb.call(*args, options) unless @prolog_cb.nil?

    # it's either :any
    if task = tasks[:any] 
      rc = task[:code].call(*args, options)
    else # or the task defined by the first argument
      (name = args.shift) or (raise "no task")
      (task = tasks[name.to_sym]) or (raise "no such task: '#{name}'")
      rc = task[:code].call(*args, options)
    end

    # post handle
    unless @epilog_cb.nil?
      rc = @epilog_cb.call(rc, *args, options)
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
    tasks[:any] = { :code => blk }
  end

  def handle name, &blk
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

