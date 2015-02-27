require 'spec_helper'

RSpec.describe SQL::Table do
  before do
    @table = SQL::Table.new
  end

  %w{name columns}.each do |meth|
    it "should have a ##{meth} attribute" do
      expect(@table).to respond_to(meth.intern)
    end
  end

  it 'should #to_s as the name' do
    @table.name = "table_name"
    expect(@table.to_s).to eq("table_name")
  end

  it 'should find a column by name' do
    column_a = double('column', :name => 'id')
    column_b = double('column', :name => 'login')
    @table.columns = [column_a, column_b]

    expect(@table.column('id')).to eq(column_a)
  end


end
