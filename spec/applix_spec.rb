require 'spec_helper'

describe Applix do

  context 'main' do
    it 'catches unknown task errors' do 
      expect { Applix.main(%w(0no-such-task)) {} }.not_to raise_error
    end

    context 'with captured I/O streams' do
      it 'prints a minimal (better than nothing?) usage line on errors' do 
        output = capture(:stdout) { Applix.main(%w(1no-such-task)) {} }
        expect(output).to match(/usage: /)
      end

      it 'suppresses the callstack on errors' do 
        output = capture(:stdout) { Applix.main(%w(expected-task-error-output)) {} }
        expect(output).to match(/ ## no such task:/)
        expect(output).not_to match(/ !! no such task:/)
      end

      it 'shows callstack on --debug option' do 
        output = capture(:stdout) { Applix.main(%w(--debug 2no-such-task)) {} }
        expect(output).to match(/ !! no such task:/)
      end

      it 'dumps a stacktrace on main with a !' do 
        expect { Applix.main!(%w(3no-such-task)) {} }.
          to raise_error /no such task:/
      end
    end
  end

  describe 'cluster' do
    it 'cluster defaults shadow globals' do
      args = %w(-c=5 cluster cmd)
      Applix.main(args, a: :global, b: 2, :cluster => {a: :cluster, c: 3}) do
        handle(:cmd) { raise 'should not be called!' }
        cluster(:cluster) do
          handle(:cmd) do |*args, options|
            options.should == {:a => :cluster, :b => 2, :c => '5'}
            args
          end
        end
      end
    end

    it 'calls cluster prolog' do
      expect(Applix.main(%w(foo a b)) do
        cluster(:foo) do
          prolog { |args, options|
            args.should == %w(a b)
            args.reverse!
          }
          handle(:a) { raise 'should not be called!' }
          handle(:b) { :b_was_called }
        end
      end).to be(:b_was_called)
    end

    it 'support :cluster for nesting' do
      args = %w(-a -b:2 foo bar p1 p2)
      expect(Applix.main(args) do
        handle(:foo) do
          raise 'should not be called!'
        end
        cluster(:foo) do
          handle(:bar) do |*args, options|
            args.should == %w(p1 p2)
            options.should == {:a => true, :b => 2}
            args
          end
        end
      end).to eq(%w{p1 p2})
    end

    it 'can even cluster clusters' do
      args = %w(foo bar f p1 p2)
      expect(Applix.main(args) do
        cluster(:foo) do
          cluster(:bar) do
            handle(:f) do |*args, options|
              args.should == %w(p1 p2)
              options.should == {}
              args
            end
          end
        end
      end).to eq(%w{p1 p2})
    end
  end #.cluster

  context 'prolog invokations' do
    it 'prolog can even temper with arguments to modify the handle sequence' do
      expect(Applix.main(['a', 'b']) do
        prolog { |args, options|
          args.should == ['a', 'b']
          args.reverse!
        }
        handle(:a) { raise 'should not be called!' }
        handle(:b) { :b_was_called }
      end).to eq(:b_was_called)
    end

    it 'prolog has read/write access to args and options' do
      Applix.main(['func']) do
        prolog { |args, options|
          args.should == ['func']
          options[:prolog] = Time.now
        }

        handle(:func) { |*_, options|
          options[:prolog]
        }
      end.should_not be_nil
    end

    it 'runs before callback before handle calls' do
      expect(Applix.main(['func']) do

        # @prolog will be available in handle invocations
        prolog {
          @prolog = :prolog
        }

        # @epilog will NOT make it into the handle invocation
        epilog { |rc, *_|
          @epilog = :epilog
          rc
        }

        handle(:func) {
          [@prolog, @epilog]
        }
      end).to eq([:prolog, nil])
    end
  end

  it 'epilog has access to task handler results' do
    expect(Applix.main(['func']) do
      # @epilog will NOT make it into the handle invocation
      epilog { |rc, *_|
        rc.should == [1, 2, 3]
        rc.reverse
      }
      handle(:func) { [1, 2, 3] }

    end).to eq([3, 2, 1])
  end

  it 'runs epilog callback after handle' do
    last_action = nil
    Applix.main([:func]) do
      epilog { |rc, *_|
        # handle was already executed
        last_action.should == :handle
        last_action = :epilog
      }
      handle(:func) {
        # epilog block should not have been executed yet
        last_action.should == nil
        last_action = :handle
      }
    end
    expect(last_action).to be(:epilog)
  end

  it 'supports :any as fallback on command lines without matching task' do
    Applix.main(%w(--opt1 foo param1 param2), {:opt2 => false}) do
      handle(:not_called) { raise "can't possible happen" }
      any do |*args, options|
        args.should == ["foo", "param1", "param2"]
        options.should == {:opt1 => true, :opt2 => false}
      end
    end
  end

  it 'any does not shadow existing tasks' do
    Applix.main(['--opt1', 'foo', "param1", "param2"], {:opt2 => false}) do
      handle(:foo) do |*args, options|
        args.should == ["param1", "param2"]
        options.should == {:opt1 => true, :opt2 => false}
      end
      any { raise "can't possible happen" }
    end
  end

  it 'supports :any when task does not depend on first arguments' do
    %w(bla fasel laber red).each do |name|
      Applix.main(['--opt1', name, "param1", "param2"], {:opt2 => false}) do
        any do |*args, options|
          args.should == [name, "param1", "param2"]
          options.should == {:opt1 => true, :opt2 => false}
        end
      end
    end
  end

  describe 'any with argsloop' do
    it 'loops over args' do
      # stubbed app simulates consuming the args while looping over app calls
      app = double(:app)
      #app.should_receive(:op1).with(%w(p1 op2 2 3 op3 4 5 6), {}).and_return(%w(op2 2 3))
      expect(app).to receive(:op1).with(%w(p1 op2 2 3 op3 4 5 6), {}).and_return(%w(op2 2 3))
      #app.should_receive(:op2).with(%w(2 3), {}).and_return(%w(op3 4 5 6))
      expect(app).to receive(:op2).with(%w(2 3), {}).and_return(%w(op3 4 5 6))
      #app.should_receive(:op3).with(%w(4 5 6), {}).and_return([])
      expect(app).to receive(:op3).with(%w(4 5 6), {}).and_return([])
      Applix.main(%w(op1 p1 op2 2 3 op3 4 5 6)) do
        handle(:not_called) { raise "can't possible happen" }
        any(argsloop: app)
      end
    end

    it 'instantiates a class instance' do
      obj = double(:obj)
      clazz = Class.new
      expect(clazz).to receive(:new).and_return(obj)
      expect(obj).to receive(:op).with([], {}).and_return([])
      Applix.main(%w(op)) do
        handle(:not_called) { raise "can't possible happen" }
        any(argsloop: clazz)
      end
    end
  end

  it 'should call actions by first argument names' do
    argv = ['func']
    expect(Applix.main(argv) do
      handle(:func) { :func_return }
    end).to be(:func_return)
  end

  it 'passes arguments to function' do
    argv = ['func', 'p1', 'p2']
    subject = Applix.main(argv) { handle(:func) {|*args, options| args} }
    expect(subject).to eq(%w(p1 p2))
  end

  it 'passes a default options hash to function' do
    argv = %w(func)
    expect(Applix.main(argv) do
      handle(:func) { |*_, options| options }
    end).to eq({})
  end

  it 'should pass a processed options hash' do
    argv = %w(-a --bar func)
    expect(Applix.main(argv) do
      handle(:func) { |*_, options| options }
    end).to include(:a => true, :bar => true)
  end

  pending 'parses dashes in string options' do
    fail '?'
  end
  
  it "should parse the old unit test..." do
    # see applix_hash_spec.rb

    #   --int=1           becomes { :int    => "1" }
    #   --int:1           becomes { :int    => 1 }
    #   --float=2.3       becomes { :float  => "2.3" }
    #   --float:2.3       becomes { :float  => 2.3 }
    #   -f:1.234          becomes { :f      => 1.234 }
    expect((Hash.from_argv ["--int=1"])[:int]).to eq("1")
    expect((Hash.from_argv ["--int:1"])[:int]).to eq(1)
    expect((Hash.from_argv ["--float=2.3"])[:float]).to eq("2.3")
    expect((Hash.from_argv ["--float:2.3"])[:float]).to eq(2.3)
    expect((Hash.from_argv ["-f:2.345"])[:f]).to eq(2.345)

    #   --txt="foo bar"   becomes { :txt    => "foo bar" }
    #   --txt:'"foo bar"' becomes { :txt    => "foo bar" }
    #   --txt:%w{foo bar} becomes { :txt    => ["foo", "bar"] }
    expect((Hash.from_argv ['--txt="foo bar"'])[:txt]).to eq("foo bar")
    expect((Hash.from_argv [%q|--txt:'"foo bar"'|])[:txt]).to eq("foo bar")
    expect((Hash.from_argv [%q|--txt:'%w{foo bar}'|])[:txt]).to eq(["foo", "bar"])

    #   --now:Time.now    becomes { :now    => Mon Jul 09 01:30:21 0200 2007 }
    #dt = Time.now - H.parse("--now:Time.now")[1]
    expect((t = (Hash.from_argv ["--now:Time.now"])[:now])).to be
  end
end


__END__

port this from unit to rspec...

class HashFromArgvTest < Test::Unit::TestCase

  # XXX this is hacking the new Hash.from_argv interface into the old
  # dissect signature to make proper reuse of the existing unit tests
  def dissect(argv)
    h = Hash.from_argv(argv)
    [h[:arguments], h.delete_if { |k, _| k == :arguments }]
  end

  def test_applix_dissect_flags
    assert_equal [[], {:foo=>true}], dissect(%w{--foo})
  end

  def test_applix_colon_option
    _, opts = dissect ["-a:%w{a b c}"]
    assert_equal({:a=>['a', 'b', 'c']}, opts)

    _, opts = dissect ["-b:(1..10)"]
    assert_equal({:b=>(1..10)}, opts)

    _, opts = dissect ["-c:Time.now"]
    assert opts[:c] < Time.now
    assert (Time.now - opts[:c]) < 0.01
  end

  def test_applix_dissect_options
    _, opts = dissect %w{-v=3.15}
    assert_equal({:v=>"3.15"}, opts)
    _, opts = dissect %w{-v:3.15}
    assert_equal({:v=>3.15}, opts)

    av, opts = dissect %w{--een --twee=3 -v:3.15}
    assert_equal [], av
    assert_equal({:een => true, :twee => "3", :v => 3.15}, opts)
  end

  def test_applix_dissect_without_options
    #assert_equal [[], {}], dissect
    #assert_equal [ARGV, {}], dissect
    %w{een twee 3 3.15 foo-bar}.inject([]) do |memo, arg|
      memo << arg
      av, opts = dissect(memo)
      assert_equal memo, av
      assert_equal({}, opts)
      memo
    end
  end
end
