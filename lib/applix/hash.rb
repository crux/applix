module ApplixHash

  module ClassMethods
    # #from_argv builds hash from ARGV like argument vector according to
    # following examples:
    #
    #   '-f'                  --> { :f      => true }
    #   '--flag'              --> { :flag   => true }
    #   '--flag:false'        --> { :flag   => false }
    #   '--flag=false'        --> { :flag   => 'false' }
    #   '--option=value'      --> { :option => "value" }
    #   '--int=1'             --> { :int    => "1" }
    #   '--float=2.3'         --> { :float  => "2.3" }
    #   '--float:2.3'         --> { :float  => 2.3 }
    #   '--txt="foo bar"'     --> { :txt    => "foo bar" }
    #   '--txt:\'"foo bar"\'' --> { :txt    => "foo bar" }
    #   '--txt:%w{foo bar}'   --> { :txt    => ["foo", "bar"] }
    #   '--now:Time.now'      --> { :now    => #<Date: 3588595/2,0,2299161> }
    #
    # remaining arguments(non flag/options) are inserted as [:args]. eg:
    #     Hash.from_argv %w(--foo --bar=loo 123 now)
    # becomes
    #     { :foo => true, :bar => 'loo', :args => ["123", "now"] }
    #
    def from_argv argv, opts = {}
      args, h = argv.clone, {}
      while arg = args.first
        key, val = ApplixHash.parse(arg)
        break unless key
        h[key] = val
        args.shift
      end
      #[args, h]
      h[:args] = args
      h
    end
  end # ClassMethods

  # parse single flag/option into a [key, value] tuple. returns nil on non
  # option/flag arguments.
  def self.parse(arg)
    m = /^(-(\w)|--(\w\w+))(([=:])(.+))?$/.match(arg)
    return [nil, arg] unless m # neither option nor flag -> straight arg
    key = (m[2] || m[3]).to_sym
    value = m[6][/(['"]?)(.*)\1$/,2] rescue true
    value = eval(value) if m[5] == ':'
    [key, value]
  end
end

Hash.extend ApplixHash::ClassMethods
