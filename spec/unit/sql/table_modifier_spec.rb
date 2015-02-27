require 'spec_helper'

RSpec.describe 'SQL module' do
  describe 'TableModifier' do
    before do
      @adapter = double('adapter')
      allow(@adapter).to receive(:quote_name).and_return(%{'users'})
      @tc = SQL::TableModifier.new(@adapter, :users) { }
    end

    describe 'initialization' do
      it 'should set @adapter to the adapter' do
        expect(@tc.instance_variable_get("@adapter")).to eq(@adapter)
      end

      it 'should set @table_name to the stringified table name' do
        expect(@tc.instance_variable_get("@table_name")).to eq('users')
      end

      it 'should set @opts to the options hash' do
        expect(@tc.instance_variable_get("@opts")).to eq({})
      end

      it 'should set @statements to an empty array' do
        expect(@tc.instance_variable_get("@statements")).to eq([])
      end

      it 'should evaluate the given block' do
        block = proc { column :foo, :bar }
        col = double('column')
        expect(SQL::TableCreator::Column).to receive(:new).with(@adapter, :foo, :bar, {}).and_return(col)
        tc = SQL::TableCreator.new(@adapter, 'users', {}, &block)
        expect(tc.instance_variable_get("@columns")).to eq([col])
      end
    end

    it 'should have a table_name' do
      expect(@tc).to respond_to(:table_name)
      expect(@tc.table_name).to eq('users')
    end

    it 'should use the adapter to quote the table name' do
      expect(@adapter).to receive(:quote_name).with('users').and_return(%{'users'})
      expect(@tc.quoted_table_name).to eq(%{'users'})
    end

  end

end
