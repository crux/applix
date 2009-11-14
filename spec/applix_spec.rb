require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Applix" do
  #it "fails" do
  #  fail "hey buddy, you should probably rename this file and start specing for real"
  #end
end


__END__

port this from unit to rspec...

#!/usr/bin/env ruby

require 'test/unit'
require 'pp'

#require 'hash_from_argv'
#H = Hash::FromArgvHelperNamespaceToAvoidPolution

require 'applix-hash'
H = ApplixHash

class HashFromArgvTest < Test::Unit::TestCase

  def test_applix_hash_parse
    #   -f                becomes { :f      => true }
    #   --flag            becomes { :flag   => true }
    assert_equal [:f, true], H.parse("-f")
    assert_equal [:flag, true], H.parse("--flag")
    #   --flag:false      becomes { :flag   => false }
    assert_equal [:flag, false], H.parse("--flag:false")

    #   --option=value    becomes { :option => "value" }
    assert_equal [:opt, "val"], H.parse("--opt=val")

    #   --int=1           becomes { :int    => "1" }
    #   --float=2.3       becomes { :float  => "2.3" }
    #   --float:2.3       becomes { :float  => 2.3 }
    #   -f:1.234          becomes { :f      => 1.234 }
    assert_equal [:int, "1"], H.parse("--int=1")
    assert_equal [:float, "2.3"], H.parse("--float=2.3")
    assert_equal [:float, 2.3], H.parse("--float:2.3")
    assert_equal [:f, 1.234], H.parse("-f:1.234")

    #   --txt="foo bar"   becomes { :txt    => "foo bar" }
    #   --txt:'"foo bar"' becomes { :txt    => "foo bar" }
    #   --txt:%w{foo bar} becomes { :txt    => ["foo", "bar"] }
    assert_equal [:txt, "foo bar"], H.parse('--txt="foo bar"')
    assert_equal [:txt, "foo bar"], H.parse(%q{--txt:'"foo bar"'})
    assert_equal [:txt, ["foo", "bar"]], H.parse(%q{--txt:'%w{foo bar}'})

    #   --now:Time.now    becomes { :now    => Mon Jul 09 01:30:21 0200 2007 }
    dt = Time.now - H.parse("--now:Time.now")[1]
    assert dt < 0.02
  end

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
