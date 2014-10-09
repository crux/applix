require 'spec_helper'

describe ApplixHash do
  it 'parses dashed string options' do
    #(ApplixHash.parse '--foo-bar').should == ["foo-bar".to_sym, true]
    expect(ApplixHash.parse '--foo-bar').to eq(["foo-bar".to_sym, true])
    #(ApplixHash.parse '--foo-bar=321').should == ["foo-bar".to_sym, '321']
    expect(ApplixHash.parse '--foo-bar=321').to eq(["foo-bar".to_sym, '321'])
  end

  it "parses the old unit test..." do
    #   -f                becomes { :f      => true }
    #   --flag            becomes { :flag   => true }
    expect(ApplixHash.parse '-f').to eq([:f, true])
    expect(ApplixHash.parse '--flag').to eq([:flag, true])
    #   --flag:false      becomes { :flag   => false }
    expect(ApplixHash.parse '--flag:false').to eq([:flag, false])

    #   --option=value    becomes { :option => "value" }
    expect(ApplixHash.parse '--opt=val').to eq([:opt, 'val'])
  end
end
