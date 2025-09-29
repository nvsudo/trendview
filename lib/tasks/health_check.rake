namespace :app do
  desc "Run comprehensive health checks (like npm build for Rails)"
  task :health_check => :environment do
    puts "🔥 Running Ignition Health Checks..."

    errors = []

    # 1. Database connectivity
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "✅ Database connection"
    rescue => e
      errors << "❌ Database: #{e.message}"
    end

    # 2. Load all models
    begin
      Rails.application.eager_load!
      puts "✅ All models loaded"
    rescue => e
      errors << "❌ Model loading: #{e.message}"
    end

    # 3. Test critical associations
    begin
      if User.any?
        user = User.first
        user.total_portfolio_value
        user.total_deployed_percentage
        user.trading_accounts.count
        puts "✅ User associations working"
      else
        puts "⚠️  No users exist (normal for new install)"
      end
    rescue => e
      errors << "❌ User associations: #{e.message}"
    end

    # 4. Test all model associations
    [User, TradingAccount, Trade, Security, AccountSnapshot, UserStockAnalysis, Session, Position, JournalEntry].each do |model|
      begin
        model.reflect_on_all_associations.each do |assoc|
          # Just reflect, don't execute queries for empty tables
          assoc.klass
        end
        puts "✅ #{model.name} associations defined correctly"
      rescue => e
        errors << "❌ #{model.name} associations: #{e.message}"
      end
    end

    # 5. Check migrations
    begin
      migrator = ActiveRecord::MigrationContext.new(
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths,
        ActiveRecord::SchemaMigration
      )
      pending = migrator.needs_migration?
      if pending
        errors << "❌ Pending migrations exist"
      else
        puts "✅ All migrations applied"
      end
    rescue => e
      puts "⚠️  Migration check skipped: #{e.message}"
    end

    # Results
    puts "\n" + "="*50
    if errors.empty?
      puts "🎉 All health checks passed! Ignition is ready."
      exit 0
    else
      puts "💥 Health check failures:"
      errors.each { |error| puts "   #{error}" }
      exit 1
    end
  end
end