require 'spec_helper'

RSpec.describe 'Migration' do
  supported_by :postgres, :mysql, :sqlite do
    before do
      @adapter = double('adapter', :class => DataMapper::Spec.adapter.class)
      @repo = double('DataMapper.repository', :adapter => @adapter)
      allow(DataMapper).to receive(:repository).and_return(@repo)
      @m = DataMapper::Migration.new(1, :do_nothing, {}) {}
      allow(@m).to receive(:write) # silence any output
    end

    [:position, :name, :database, :adapter].each do |meth|
      it "should respond to ##{meth}" do
        expect(@m).to respond_to(meth)
      end
    end

    describe 'initialization' do
      it 'should set @position from the given position' do
        expect(@m.instance_variable_get(:@position)).to eq(1)
      end

      it 'should set @name from the given name' do
        expect(@m.instance_variable_get(:@name)).to eq(:do_nothing)
      end

      it 'should set @options from the options hash' do
        expect(@m.instance_variable_get(:@options)).to eq({})
      end

      it 'should set @repository from the default repository if no :repository option is given' do
        m = DataMapper::Migration.new(1, :do_nothing, {}) {}

        expect(m.instance_variable_get(:@repository)).to eq(:default)
      end

      it 'should set @repository to the specified :repository option' do
        m = DataMapper::Migration.new(1, :do_nothing, :repository => :foobar) {}

        expect(m.instance_variable_get(:@repository)).to eq(:foobar)
      end

      it 'should set @verbose from the options hash' do
        m = DataMapper::Migration.new(1, :do_nothing, :verbose => false) {}
        expect(m.instance_variable_get(:@verbose)).to be(false)
      end

      it 'should set @verbose to true by default' do
        expect(@m.instance_variable_get(:@verbose)).to be(true)
      end

      it 'should set the @up_action to nil' do
        expect(@m.instance_variable_get(:@up_action)).to be_nil
      end

      it 'should set the @down_action to nil' do
        expect(@m.instance_variable_get(:@down_action)).to be_nil
      end

      it 'should evaluate the given block'

    end

    it 'should set the @up_action when #up is called with a block' do
      action = lambda {}
      @m.up(&action)
      expect(@m.instance_variable_get(:@up_action)).to eq(action)
    end

    it 'should set the @up_action when #up is called with a block' do
      action = lambda {}
      @m.down(&action)
      expect(@m.instance_variable_get(:@down_action)).to eq(action)
    end

    describe 'adapter' do
      before(:each) do
        @m.instance_variable_set(:@adapter, nil)
      end

      it 'should determine the class of the adapter to be extended' do
        expect(@adapter).to receive(:class).and_return(DataMapper::Spec.adapter.class)

        @m.adapter
      end

      it 'should extend the adapter with the right module' do
        expect(@adapter).to receive(:extend).with(SQL.const_get(DataMapper::Spec.adapter_name.capitalize))

        @m.adapter
      end

      it 'should raise "Unsupported adapter" on an unknown adapter' do
        allow(@adapter).to receive(:class).and_return("InvalidAdapter")

        expect { @m.adapter }.to raise_error
      end
    end

    describe 'perform_up' do
      before do
        @up_action = double('proc', :call => true)
        @m.instance_variable_set(:@up_action, @up_action)
        allow(@m).to receive(:needs_up?).and_return(true)
        allow(@m).to receive(:update_migration_info)
      end

      it 'should call the action assigned to @up_action and return the result' do
        expect(@up_action).to receive(:call).and_return(:result)
        expect(@m.perform_up).to eq(:result)
      end

      it 'should output a status message with the position and name of the migration' do
        expect(@m).to receive(:write).with(/Performing Up Migration #1: do_nothing/)
        @m.perform_up
      end

      it 'should not run if it doesnt need to be' do
        expect(@m).to receive(:needs_up?).and_return(false)
        expect(@up_action).not_to receive(:call)
        @m.perform_up
      end

      it 'should update the migration info table' do
        expect(@m).to receive(:update_migration_info).with(:up)
        @m.perform_up
      end

      it 'should not update the migration info table if the migration does not need run' do
        expect(@m).to receive(:needs_up?).and_return(false)
        expect(@m).not_to receive(:update_migration_info)
        @m.perform_up
      end

    end

    describe 'perform_down' do
      before do
        @down_action = double('proc', :call => true)
        @m.instance_variable_set(:@down_action, @down_action)
        allow(@m).to receive(:needs_down?).and_return(true)
        allow(@m).to receive(:update_migration_info)
      end

      it 'should call the action assigned to @down_action and return the result' do
        expect(@down_action).to receive(:call).and_return(:result)
        expect(@m.perform_down).to eq(:result)
      end

      it 'should output a status message with the position and name of the migration' do
        expect(@m).to receive(:write).with(/Performing Down Migration #1: do_nothing/)
        @m.perform_down
      end

      it 'should not run if it doesnt need to be' do
        expect(@m).to receive(:needs_down?).and_return(false)
        expect(@down_action).not_to receive(:call)
        @m.perform_down
      end

      it 'should update the migration info table' do
        expect(@m).to receive(:update_migration_info).with(:down)
        @m.perform_down
      end

      it 'should not update the migration info table if the migration does not need run' do
        expect(@m).to receive(:needs_down?).and_return(false)
        expect(@m).not_to receive(:update_migration_info)
        @m.perform_down
      end

    end

    describe 'methods used in the action blocks' do

      describe '#execute' do
        before do
          allow(@adapter).to receive(:execute)
        end

        it 'should send the SQL it its executing to the adapter execute method' do
          expect(@adapter).to receive(:execute).with('SELECT SOME SQL')
          @m.execute('SELECT SOME SQL')
        end

        it 'should output the SQL it is executing' do
          expect(@m).to receive(:write).with(/SELECT SOME SQL/)
          @m.execute('SELECT SOME SQL')
        end
      end

      describe '#execute' do
        before do
          allow(@adapter).to receive(:select)
        end

        it 'should send the SQL it its executing to the adapter execute method' do
          expect(@adapter).to receive(:select).with('SELECT SOME SQL')
          @m.select('SELECT SOME SQL')
        end

        it 'should output the SQL it is executing' do
          expect(@m).to receive(:write).with(/SELECT SOME SQL/)
          @m.select('SELECT SOME SQL')
        end
      end

      describe 'helpers' do
        before do
          allow(@m).to receive(:execute) # don't actually run anything
        end

        describe '#create_table' do
          before do
            @tc = double('TableCreator', :to_sql => 'CREATE TABLE')
            allow(SQL::TableCreator).to receive(:new).and_return(@tc)
          end

          it 'should create a new TableCreator object' do
            expect(SQL::TableCreator).to receive(:new).with(@adapter, :users, {}).and_return(@tc)
            @m.create_table(:users) { }
          end

          it 'should convert the TableCreator object to an sql statement' do
            expect(@tc).to receive(:to_sql).and_return('CREATE TABLE')
            @m.create_table(:users) { }
          end

          it 'should execute the create table sql' do
            expect(@m).to receive(:execute).with('CREATE TABLE')
            @m.create_table(:users) { }
          end

        end

        describe '#drop_table' do
          it 'should quote the table name' do
            expect(@adapter).to receive(:quote_name).with('users')
            @m.drop_table :users
          end

          it 'should execute the DROP TABLE sql for the table' do
            allow(@adapter).to receive(:quote_name).and_return("'users'")
            expect(@m).to receive(:execute).with(%{DROP TABLE 'users'})
            @m.drop_table :users
          end

        end

        describe '#modify_table' do
          before do
            @tm = double('TableModifier', :statements => [])
            allow(SQL::TableModifier).to receive(:new).and_return(@tm)
          end

          it 'should create a new TableModifier object' do
            expect(SQL::TableModifier).to receive(:new).with(@adapter, :users, {}).and_return(@tm)
            @m.modify_table(:users){ }
          end

          it 'should get the statements from the TableModifier object' do
            expect(@tm).to receive(:statements).and_return([])
            @m.modify_table(:users){ }
          end

          it 'should iterate over the statements and execute each one' do
            expect(@tm).to receive(:statements).and_return(['SELECT 1', 'SELECT 2'])
            expect(@m).to receive(:execute).with('SELECT 1')
            expect(@m).to receive(:execute).with('SELECT 2')
            @m.modify_table(:users){ }
          end

        end

        describe 'sorting' do
          it 'should order things by position' do
            m1 = DataMapper::Migration.new(1, :do_nothing){}
            m2 = DataMapper::Migration.new(2, :do_nothing_else){}

            expect(m1 <=> m2).to eq(-1)
          end

          it 'should order things by name when they have the same position' do
            m1 = DataMapper::Migration.new(1, :do_nothing_a){}
            m2 = DataMapper::Migration.new(1, :do_nothing_b){}

            expect(m1 <=> m2).to eq(-1)
          end

        end

        describe 'formatting output' do
          describe '#say' do
            it 'should output the message' do
              expect(@m).to receive(:write).with(/Paul/)
              @m.say("Paul")
            end

            it 'should indent the message with 4 spaces by default' do
              expect(@m).to receive(:write).with(/^\s{4}/)
              @m.say("Paul")
            end

            it 'should indext the message with a given number of spaces' do
              expect(@m).to receive(:write).with(/^\s{3}/)
              @m.say("Paul", 3)
            end
          end

          describe '#say_with_time' do
            before do
              allow(@m).to receive(:say)
            end

            it 'should say the message with an indent of 2' do
              expect(@m).to receive(:say).with("Paul", 2)
              @m.say_with_time("Paul"){}
            end

            it 'should output the time it took' do
              expect(@m).to receive(:say).with(/\d+/, 2)
              @m.say_with_time("Paul"){}
            end
          end

          describe '#write' do
            before do
              # need a new migration object, because the main one had #write stubbed to silence output
              @m = DataMapper::Migration.new(1, :do_nothing) {}
            end

            it 'should puts the message' do
              expect(@m).to receive(:puts).with("Paul")
              @m.write("Paul")
            end

            it 'should not puts the message if @verbose is false' do
              @m.instance_variable_set(:@verbose, false)
              expect(@m).not_to receive(:puts)
              @m.write("Paul")
            end

          end

        end

        describe 'working with the migration_info table' do
          before do
            allow(@adapter).to receive(:storage_exists?).and_return(true)
            # --- Please remove stubs ---
            allow(@adapter).to receive(:quote_name) { |name| "'#{name}'" }
          end

          describe '#update_migration_info' do
            it 'should add a record of the migration' do
              expect(@m).to receive(:execute).with(
                %Q{INSERT INTO 'migration_info' ('migration_name') VALUES ('do_nothing')}
              )
              @m.update_migration_info(:up)
            end

            it 'should remove the record of the migration' do
              expect(@m).to receive(:execute).with(
                %Q{DELETE FROM 'migration_info' WHERE 'migration_name' = 'do_nothing'}
              )
              @m.update_migration_info(:down)
            end

            it 'should try to create the migration_info table' do
              expect(@m).to receive(:create_migration_info_table_if_needed)
              @m.update_migration_info(:up)
            end
          end

          describe '#create_migration_info_table_if_needed' do
            it 'should create the migration info table' do
              expect(@m).to receive(:migration_info_table_exists?).and_return(false)
              expect(@m).to receive(:execute).with(
                %Q{CREATE TABLE 'migration_info' ('migration_name' VARCHAR(255) UNIQUE)}
              )
              @m.create_migration_info_table_if_needed
            end

            it 'should not try to create the migration info table if it already exists' do
              expect(@m).to receive(:migration_info_table_exists?).and_return(true)
              expect(@m).not_to receive(:execute)
              @m.create_migration_info_table_if_needed
            end
          end

          it 'should quote the name of the migration for use in sql' do
            expect(@m.quoted_name).to eq(%{'do_nothing'})
          end

          it 'should query the adapter to see if the migration_info table exists' do
            expect(@adapter).to receive(:storage_exists?).with('migration_info').and_return(true)
            expect(@m.migration_info_table_exists?).to eq(true)
          end

          describe '#migration_record' do
            it 'should query for the migration' do
              expect(@adapter).to receive(:select).with(
                %Q{SELECT 'migration_name' FROM 'migration_info' WHERE 'migration_name' = 'do_nothing'}
              )
              @m.migration_record
            end

            it 'should not try to query if the table does not exist' do
              allow(@m).to receive(:migration_info_table_exists?).and_return(false)
              expect(@adapter).not_to receive(:select)
              @m.migration_record
            end

          end

          describe '#needs_up?' do
            it 'should be true if there is no record' do
              expect(@m).to receive(:migration_record).and_return([])
              expect(@m.needs_up?).to eq(true)
            end

            it 'should be false if the record exists' do
              expect(@m).to receive(:migration_record).and_return([:not_empty])
              expect(@m.needs_up?).to eq(false)
            end

            it 'should be true if there is no migration_info table' do
              expect(@m).to receive(:migration_info_table_exists?).and_return(false)
              expect(@m.needs_up?).to eq(true)
            end

          end

          describe '#needs_down?' do
            it 'should be false if there is no record' do
              expect(@m).to receive(:migration_record).and_return([])
              expect(@m.needs_down?).to eq(false)
            end

            it 'should be true if the record exists' do
              expect(@m).to receive(:migration_record).and_return([:not_empty])
              expect(@m.needs_down?).to eq(true)
            end

            it 'should be false if there is no migration_info table' do
              expect(@m).to receive(:migration_info_table_exists?).and_return(false)
              expect(@m.needs_down?).to eq(false)
            end

          end

          it 'should have the adapter quote the migration_info table' do
            expect(@adapter).to receive(:quote_name).with('migration_info').and_return("'migration_info'")
            expect(@m.migration_info_table).to eq("'migration_info'")
          end

          it 'should have a quoted migration_name_column' do
            expect(@adapter).to receive(:quote_name).with('migration_name').and_return("'migration_name'")
            expect(@m.migration_name_column).to eq("'migration_name'")
          end

        end

      end

    end
  end
end
