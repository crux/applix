require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Applix" do

  it 'cluster defaults shadow globals' do
    args = %w(-c=5 global cluster)
    Applix.main(args, a: :global, b: 2, :cluster => {a: :cluster, c: 3}) do
      handle(:cluster) do 
        raise 'should not be called!'
      end
      cluster(:global) do
        handle(:cluster) do |*args, options|
          options.should == {:a => :cluster, :b => 2, :c => '5'}
          args
        end
      end
    end
  end

  it 'calls cluster prolog' do
    Applix.main(%w(foo a b)) do
      cluster(:foo) do
        prolog { |args, options|
          args.should == %w(a b)
          args.reverse!
        }
        handle(:a) { raise 'should not be called!' }
        handle(:b) { :b_was_called }
      end
    end.should == :b_was_called
  end

  it 'support :cluster for nesting' do
    args = %w(-a -b:2 foo bar p1 p2)
    Applix.main(args) do
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
    end.should == %w{p1 p2}
  end

  it 'can even cluster clusters' do
    args = %w(foo bar f p1 p2)
    Applix.main(args) do
      cluster(:foo) do
        cluster(:bar) do
          handle(:f) do |*args, options|
            args.should == %w(p1 p2)
            options.should == {}
            args
          end
        end
      end
    end.should == %w{p1 p2}
  end

  it 'prolog can even temper with arguments to modify the handle sequence' do
    Applix.main(['a', 'b']) do
      prolog { |args, options|
        args.should == ['a', 'b']
        args.reverse!
      }
      handle(:a) { raise 'should not be called!' }
      handle(:b) { :b_was_called }
    end.should == :b_was_called
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
    end.should_not == nil
  end

  it 'epilog has access to task handler results' do
    Applix.main(['func']) do
      # @epilog will NOT make it into the handle invocation
      epilog { |rc, *_| 
        rc.should == [1, 2, 3]
        rc.reverse
      }
      handle(:func) { [1, 2, 3] }

    end.should == [3, 2, 1]
  end

  it 'runs before callback before handle calls' do
    Applix.main(['func']) do

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
    end.should == [:prolog, nil]
  end

  it 'runs epilog callback after handle' do
    t_handle = Applix.main([:func]) do
      epilog { |rc, *_| 
        $t_post_handle = Time.now 
        rc
      }
      handle(:func) { 
        # epilog block should not have been executed yet
        $t_post_handle.should == nil
        Time.now 
      }
    end
    t_handle.should_not == nil
    $t_post_handle.should_not == nil
    (t_handle < $t_post_handle).should == true
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

  it 'should call actions by first argument names' do
    argv = ['func']
    Applix.main(argv) do
      handle(:func) { :func_return }
    end.should == :func_return
  end

  it 'should pass arguments to function' do
    argv = ['func', 'p1', 'p2']
    Applix.main(argv) do
      handle(:func) { |*args, options| args }
    end.should == %w{p1 p2}
  end

  it 'should pass emtpy options to function on default' do
    argv = %w(func)
    Applix.main(argv) do
      handle(:func) { |*_, options| options }
    end.should == {}
  end

  it 'should pass a processed options hash' do
    argv = %w(-a --bar func)
    Applix.main(argv) do
      handle(:func) { |*_, options| options }
    end.should == {:a => true, :bar => true}
  end

  it "should parse the old unit test..." do
    #   -f                becomes { :f      => true }
    #   --flag            becomes { :flag   => true }
    (ApplixHash.parse '-f').should == [:f, true]
    (ApplixHash.parse '--flag').should == [:flag, true]
    #   --flag:false      becomes { :flag   => false }
    (ApplixHash.parse '--flag:false').should == [:flag, false]

    #   --option=value    becomes { :option => "value" }
    (ApplixHash.parse '--opt=val').should == [:opt, 'val']

    #   --int=1           becomes { :int    => "1" }
    #   --int:1           becomes { :int    => 1 }
    #   --float=2.3       becomes { :float  => "2.3" }
    #   --float:2.3       becomes { :float  => 2.3 }
    #   -f:1.234          becomes { :f      => 1.234 }
    (Hash.from_argv ["--int=1"])[:int].should == "1"
    (Hash.from_argv ["--int:1"])[:int].should == 1
    (Hash.from_argv ["--float=2.3"])[:float].should == "2.3"
    (Hash.from_argv ["--float:2.3"])[:float].should == 2.3
    (Hash.from_argv ["-f:2.345"])[:f].should == 2.345

    #   --txt="foo bar"   becomes { :txt    => "foo bar" }
    #   --txt:'"foo bar"' becomes { :txt    => "foo bar" }
    #   --txt:%w{foo bar} becomes { :txt    => ["foo", "bar"] }
    (Hash.from_argv ['--txt="foo bar"'])[:txt].should == "foo bar"
    (Hash.from_argv [%q|--txt:'"foo bar"'|])[:txt].should == "foo bar"
    (Hash.from_argv [%q|--txt:'%w{foo bar}'|])[:txt].should == ["foo", "bar"]

    #   --now:Time.now    becomes { :now    => Mon Jul 09 01:30:21 0200 2007 }
    #dt = Time.now - H.parse("--now:Time.now")[1]
    (t = (Hash.from_argv ["--now:Time.now"])[:now]).should_not == nil
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
