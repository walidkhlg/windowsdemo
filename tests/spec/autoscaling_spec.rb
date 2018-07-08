require 'spec_helper'

autoscaling_group = "tf-asg-20180704072736791600000002"

describe autoscaling_group(autoscaling_group) do
  it { should exist }
  it { should have_elb('web-elb') }
end
describe launch_configuration('web-lc-20180704072736066100000001') do
  it { should exist }
end
