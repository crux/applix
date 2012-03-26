require 'spec_helper'

describe OAttr do
  it "should define a module" do
    OAttr.should_not == nil
  end

  #it "should define a oattr class method" do
  #  OAttr.oattr.should_not == nil
  #end

  describe "with an included OAttr module" do
    before :each do
      class Foo; include OAttr; end
    end
    it "should include the oattr class method" do
      Foo.oattr.should_not == nil
    end
    it "should define a bar method" do
      class Foo; 
        oattr :bar
        def initialize; @options = { :bar => 123}; end; 
      end
      (Foo.new.respond_to? :bar).should == true
      Foo.new.bar.should == 123
    end

    it "should handle container options" do
      class Foo; 
        oattr :xxx, :foo, :container => :params
        def initialize; @params = { :xxx => 321}; end; 
      end
      (Foo.new.respond_to? :xxx).should == true
      Foo.new.xxx.should == 321
    end
  end
end
