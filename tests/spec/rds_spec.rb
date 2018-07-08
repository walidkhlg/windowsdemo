require 'spec_helper'

rds_instance = "demodb"

describe rds(rds_instance) do
  it { should belong_to_vpc('vpc-0665f760') }
  it { should belong_to_db_subnet_group('main') }
end
