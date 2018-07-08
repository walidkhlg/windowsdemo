require 'spec_helper'

vpc_id = "vpc-0665f760"
describe vpc(vpc_id) do
  it { should exist }
  it { should be_available }
end
