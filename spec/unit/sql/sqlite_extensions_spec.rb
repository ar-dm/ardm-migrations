require 'spec_helper'

# a dummy class to include the module into
class SqliteExtension
  include SQL::Sqlite
end

RSpec.describe "SQLite3 Extensions" do
  before do
    @se = SqliteExtension.new
  end

  it 'should support schema-level transactions' do
    expect(@se.supports_schema_transactions?).to be(true)
  end

  it 'should support the serial column attribute' do
    expect(@se.supports_serial?).to be(true)
  end

  it 'should create a table object from the name' do
    table = double('SQLite3 Table')
    expect(SQL::Sqlite::Table).to receive(:new).with(@se, 'users').and_return(table)

    expect(@se.table('users')).to eq(table)
  end

  describe 'recreating the database' do
    before do
      uri = double('URI', :path => '/foo/bar.db')
      @se.instance_variable_set('@uri', uri)
    end

    it 'should rm the db file' do
      expect(FileUtils).to receive(:rm_f).with('/foo/bar.db')
      @se.recreate_database
    end

  end

  describe 'Table' do
    before do
      @cs1 = double('Column Struct')
      @cs2 = double('Column Struct')
      @adapter = double('adapter')
      allow(@adapter).to receive(:table_info).with('users').and_return([@cs1, @cs2])

      @col1 = double('SQLite3 Column')
      @col2 = double('SQLite3 Column')
    end

    it 'should initialize columns by querying the table' do
      expect(SQL::Sqlite::Column).to receive(:new).with(@cs1).and_return(@col1)
      expect(SQL::Sqlite::Column).to receive(:new).with(@cs2).and_return(@col2)
      expect(@adapter).to receive(:table_info).with('users').and_return([@cs1,@cs2])
      SQL::Sqlite::Table.new(@adapter, 'users')
    end

    it 'should create SQLite3 Column objects from the returned column structs' do
      expect(SQL::Sqlite::Column).to receive(:new).with(@cs1).and_return(@col1)
      expect(SQL::Sqlite::Column).to receive(:new).with(@cs2).and_return(@col2)
      SQL::Sqlite::Table.new(@adapter, 'users')
    end

    it 'should set the @columns to the looked-up columns' do
      expect(SQL::Sqlite::Column).to receive(:new).with(@cs1).and_return(@col1)
      expect(SQL::Sqlite::Column).to receive(:new).with(@cs2).and_return(@col2)
      t = SQL::Sqlite::Table.new(@adapter, 'users')
      expect(t.columns).to eq([ @col1, @col2 ])
    end

  end

  describe 'Column' do
    before do
      @cs = double('Struct',
                 :name       => 'id',
                 :type       => 'integer',
                 :dflt_value => 123,
                 :pk         => true,
                 :notnull    => 0)
      @c = SQL::Sqlite::Column.new(@cs)
    end

    it 'should set the name from the name value' do
      expect(@c.name).to eq('id')
    end

    it 'should set the type from the type value' do
      expect(@c.type).to eq('integer')
    end

    it 'should set the default_value from the dflt_value value' do
      expect(@c.default_value).to eq(123)
    end

    it 'should set the primary_key from the pk value' do
      expect(@c.primary_key).to eq(true)
    end

    it 'should set not_null based on the notnull value' do
      expect(@c.not_null).to eq(true)
    end

  end


end
