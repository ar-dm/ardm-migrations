RSpec.shared_examples_for "require 'dm-migrations'" do

  it "should include the migration api in the DataMapper namespace" do
    expect(DataMapper.respond_to?(:migrate!                )).to be(true)
    expect(DataMapper.respond_to?(:auto_migrate!           )).to be(true)
    expect(DataMapper.respond_to?(:auto_upgrade!           )).to be(true)
    expect(DataMapper.respond_to?(:auto_migrate_up!,   true)).to be(true)
    expect(DataMapper.respond_to?(:auto_migrate_down!, true)).to be(true)
  end

  %w[ Repository Model ].each do |name|
    it "should include the migration api in DataMapper::#{name}" do
      expect(DataMapper.const_get(name) < DataMapper::Migrations.const_get(name)).to be(true)
    end
  end

  it "should include the migration api into the adapter" do
    expect(@adapter.respond_to?(:storage_exists?      )).to be(true)
    expect(@adapter.respond_to?(:field_exists?        )).to be(true)
    expect(@adapter.respond_to?(:upgrade_model_storage)).to be(true)
    expect(@adapter.respond_to?(:create_model_storage )).to be(true)
    expect(@adapter.respond_to?(:destroy_model_storage)).to be(true)
  end

end
