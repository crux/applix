require 'applix/hash'

# command line options & argument routing. Typical usage Applix.main(ARGV).
# see also: ApplixHash for argument parsing options.
#
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

    # cluster for nesting or direct calling?
    if task[:cluster]
      #rc = Applix.main(args, options, &task[:code])
      cluster_task = task[:name].to_sym
      cluster_options = options.merge(options[cluster_task] || {})
      cluster_options.delete(cluster_task)
      cluster_options.merge!(Hash.from_argv argv)
      rc = Applix.main(args, cluster_options, &task[:code])
    else
      rc = task[:code].call(*args, options)
    end

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

  def cluster name, &blk
    tasks[name.to_sym] = { :name => name, :code => blk, :cluster => true }
  end

  def handle name, &blk
    tasks[name.to_sym] = { :name => name, :code => blk }
  end

  def tasks
    @tasks ||= {}
  end
end
