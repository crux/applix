require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Applix" do
  #it "fails" do
  #  fail "hey buddy, you should probably rename this file and start specing for real"
  #end
  
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