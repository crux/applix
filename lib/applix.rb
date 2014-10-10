require 'applix/hash'

# command line options & argument routing controller. A typical usage
# Applix.main(ARGV).  see also: ApplixHash for argument parsing options.
#
class Applix

  #  prints primitve usage in case of error,
  #
  def self.main argv, app_defaults = {}, &blk
    self.main!(argv, app_defaults, &blk)

  rescue => e
    puts <<-TXT

 ## #{e}

usage: #{$0} <args...>

    TXT
  end

  #  raises exception on error 
  #  dumps callstack in case of error when --debug is enabled
  #
  def self.main! argv, app_defaults = {}, &blk
    app = Applix.new(app_defaults.merge(Hash.from_argv argv))
    app.instance_eval(&blk)
    app.run(argv, app_defaults, &blk)

  rescue => e
    #app.debug? and (puts %[ !! #{e}:\n#{e.backtrace.join "\n"}])
    (puts %[ !! #{e}:\n#{e.backtrace.join "\n"}]) if app.debug? 
    raise
  end

  def debug?
    @options[:debug] == true
  end

  def run argv, defaults = {}
    # run defaults are overloaded with argv command line options
    run_options = defaults.merge(Hash.from_argv argv)
    args = (run_options.delete :args)

    # pre handle, can modify args & options
    @prolog_cb.call(args, run_options) unless @prolog_cb.nil?

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

    # case #4: we must un-shift the name back into the args list to let :any
    # still sees it as first argument,
    (args.unshift name.to_s) if(name != :any && task[:name] == :any)

    # cluster for nesting or direct calling?
    if task[:cluster]
      #rc = Applix.main(args, options, &task[:code])
      cluster_task = task[:name].to_sym
      cluster_options = run_options.merge(run_options[cluster_task] || {})
      cluster_options.delete(cluster_task)
      cluster_options.merge!(Hash.from_argv argv)
      rc = Applix.main(args, cluster_options, &task[:code])
    else
      rc = task[:code].call(*args, run_options)
    end

    # post handle
    unless @epilog_cb.nil?
      rc = @epilog_cb.call(rc, args, run_options)
    end

    rc # return result code from handle callbacks, not the epilog_cb
  end

  private

  Defaults = {
    debug:  false,
  }

  def initialize app_defaults = {}
    @options = (Defaults.merge app_defaults)
  end

  def prolog &blk
    @prolog_cb = blk
  end

  def epilog &blk
    @epilog_cb = blk
  end

  # opts[:argsloop], the target for any, may be be class or an object. In case
  # of class we instantiate an object from it, other we use the object itself
  def any(opts = {}, &blk)
    if(app = opts[:argsloop]) 

      blk = lambda do |*args, opts|
        # instantiate or assign target object before first usage
        target = (app.is_a? Class) ? app.new(opts) : app

        while(args && 0 < args.size) do
          args = begin
                   if(op = args.shift)
                     puts " --(#{op})-- (#{args.join ', '})"
                     if(target == app)
                       # object target
                       target.send(op, args, opts)
                     else
                       # object instance created from class target 
                       target.send(op, *args)
                     end
                   end
                 rescue ArgumentError => e
                   target.send(op, opts)
                 end
        end
      end
    end

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
