require 'spec_helper'

describe ApplixHash do
  it 'parses dashed string options' do
    (ApplixHash.parse '--foo-bar').should == ["foo-bar".to_sym, true]
    (ApplixHash.parse '--foo-bar=321').should == ["foo-bar".to_sym, '321']
  end

  it "parses the old unit test..." do
    #   -f                becomes { :f      => true }
    #   --flag            becomes { :flag   => true }
    (ApplixHash.parse '-f').should == [:f, true]
    (ApplixHash.parse '--flag').should == [:flag, true]
    #   --flag:false      becomes { :flag   => false }
    (ApplixHash.parse '--flag:false').should == [:flag, false]

    #   --option=value    becomes { :option => "value" }
    (ApplixHash.parse '--opt=val').should == [:opt, 'val']
  end
end
