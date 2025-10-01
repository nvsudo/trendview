class CreateEnumTypes < ActiveRecord::Migration[8.0]
  def up
    # Create all enum types needed by our models
    execute <<-SQL
      CREATE TYPE user_role AS ENUM ('trader', 'admin');
      CREATE TYPE trading_account_type AS ENUM ('personal', 'aggressive', 'conservative', 'family', 'retirement');
      CREATE TYPE account_status AS ENUM ('active', 'inactive', 'syncing', 'error');
      CREATE TYPE conviction_level AS ENUM ('low', 'medium', 'high', 'very_high');
      CREATE TYPE trade_type AS ENUM ('buy', 'sell');
      CREATE TYPE trade_timeframe AS ENUM ('intraday', 'swing', 'positional', 'long_term');
      CREATE TYPE trade_status AS ENUM ('open', 'closed', 'partial');
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE IF EXISTS user_role;
      DROP TYPE IF EXISTS trading_account_type;
      DROP TYPE IF EXISTS account_status;
      DROP TYPE IF EXISTS conviction_level;
      DROP TYPE IF EXISTS trade_type;
      DROP TYPE IF EXISTS trade_timeframe;
      DROP TYPE IF EXISTS trade_status;
    SQL
  end
end
