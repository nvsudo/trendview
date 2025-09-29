# TradeFlow Implementation Specification
## 5 Milestones to Phase 1 MVP

### Project Overview
Build a momentum trading journal for Indian markets by reusing Maybe's solid Rails foundation and adding trading-specific features. Focus on post-purchase trade management, risk analysis, and performance tracking.

---

## Technical Foundation

### Tech Stack (Inherited from Maybe)
- **Backend**: Ruby on Rails 7.2.2
- **Database**: PostgreSQL with existing schema patterns
- **Frontend**: Turbo + Stimulus (reuse Maybe's approach)
- **Styling**: Tailwind CSS (leverage existing classes and components)
- **Background Jobs**: Sidekiq (already configured)
- **Authentication**: Devise pattern (extend existing User model)
- **Multi-Tenancy**: ActsAsTenant gem for row-level isolation
- **Deployment**: Railway (MVP) → Render (Growth) → DigitalOcean (Scale)

### Key Dependencies to Add
```ruby
# Gemfile additions
gem 'kiteconnect'          # Zerodha API integration
gem 'acts_as_tenant'       # Multi-tenant row-level security
gem 'prawn'                # PDF generation
gem 'prawn-table'          # PDF tables
gem 'image_processing'     # Screenshot handling
gem 'sentry-ruby'          # Error monitoring
gem 'sentry-rails'         # Rails-specific error tracking
```

### Design Guidelines
- **Reuse Maybe's UI Components**: Navigation, forms, tables, modals
- **Extend Existing Patterns**: Follow Maybe's controller/view structure
- **Trading-Specific Colors**: Add green/red color scheme for P&L
- **Mobile-First**: Leverage existing Tailwind responsive design
- **Component Consistency**: Use Maybe's button, input, and card styles

---

## Phase 1 Requirements

### Core Features to Deliver
1. Multi-account Zerodha integration and portfolio sync
2. Manual trade entry with custom stage/RS fields
3. Trading journal with screenshots and notes
4. Position sizing calculator and risk management
5. Performance analytics dashboard
6. CSV/PDF export functionality
7. Watchlist management with price alerts
8. Mobile-responsive interface

### Success Criteria
- Connect and sync multiple Zerodha accounts
- Import trades automatically with 99% accuracy
- Manual trade entry takes <2 minutes
- Generate PDF reports and CSV exports
- Mobile interface works on all screen sizes
- Page load times <2 seconds

---

## Milestone 1: Foundation & UI Setup (Week 1-2)
**Goal**: Get basic app running with Maybe's UI framework extended for trading

### 1.1 Repository Setup
- Fork/clone Maybe repository
- Remove unused financial features (plaid, accounts, etc.)
- Keep core user authentication and UI framework
- Update branding to TradeFlow

### 1.2 Database Schema Migration
```ruby
# Keep from Maybe
- users table (extend with subscription_plan)
- existing authentication system
- Sidekiq configuration

# Add new tables
- trading_accounts (Zerodha account connections)
- securities (centralized stock data)
- user_stock_analysis (manual stage/RS data)
- trades (account-specific trading records)
```

### 1.3 UI Component Extension
- **Reuse**: Maybe's navigation, forms, buttons, modals
- **Extend**: Add trading-specific color scheme (green/red P&L)
- **Create**: Trading dashboard layout using existing grid system
- **Mobile**: Ensure existing responsive patterns work

### 1.4 Basic Routing Structure
```ruby
# routes.rb additions
resources :trading_accounts
resources :trades
resources :journal_entries
resources :watchlists
resources :securities
```

**Deliverable**: Basic Rails app with extended UI running locally

---

## Milestone 2: Zerodha Integration (Week 3-4)
**Goal**: Connect multiple Zerodha accounts and sync portfolio data

### 2.1 Zerodha OAuth Integration
- Implement Kite Connect OAuth flow
- Store encrypted API credentials per trading account
- Handle token refresh and error scenarios

### 2.2 Portfolio Data Sync
```ruby
class ZerodhaApiService
  def sync_portfolio(trading_account)
    # Import positions and holdings
    # Link to centralized securities table
    # Update account snapshots
  end
end
```

### 2.3 Account Management UI
- **Reuse**: Maybe's account connection patterns
- **Create**: Multi-account dashboard
- **Display**: Account overview with % deployed, cash balance
- **Switch**: Easy account switching in navigation

### 2.4 Background Jobs Setup
- Portfolio sync job (every 15 minutes during market hours)
- Price update job (centralized for all users)
- Account snapshot job (daily)

**Deliverable**: Multiple Zerodha accounts connected with live portfolio sync

---

## Milestone 3: Trade Management (Week 5-7)
**Goal**: Core trade entry, journal, and position management

### 3.1 Trade Import System
- Automatically import completed trades from Zerodha
- Map to securities table with live pricing
- Handle partial fills and trade corrections

### 3.2 Manual Trade Entry
- **Form**: Quick trade entry with symbol search
- **Fields**: Entry/exit price, quantity, custom stage (1-4), RS rank (1-10)
- **Strategy**: Dropdown for strategy types
- **Screenshots**: Image upload with annotation

### 3.3 Trading Journal
```ruby
class JournalEntry < ApplicationRecord
  belongs_to :trade
  validates :entry_rationale, presence: true
  has_many_attached :screenshots
end
```

### 3.4 Position Management UI
- **Reuse**: Maybe's table components for position display
- **Extend**: Add P&L color coding, risk metrics
- **Mobile**: Responsive tables with swipe actions

**Deliverable**: Complete trade entry and journaling system

---

## Milestone 4: Risk Management & Analytics (Week 8-10)
**Goal**: Position sizing, risk tools, and performance tracking

### 4.1 Position Sizing Calculator
```ruby
class PositionSizingCalculator
  def calculate(account_size, risk_percentage, entry_price, stop_loss)
    risk_amount = account_size * (risk_percentage / 100.0)
    risk_per_share = entry_price - stop_loss
    (risk_amount / risk_per_share).floor
  end
end
```

### 4.2 Risk Management Dashboard
- Portfolio heat map (total risk across positions)
- Account-level risk settings
- Stop loss tracking and alerts
- Risk/reward ratio calculations

### 4.3 Performance Analytics
- **Metrics**: Win rate, profit factor, average R-multiple
- **Charts**: Use Chart.js for simple visualizations
- **Breakdown**: Performance by strategy and time period
- **Mobile**: Touch-friendly chart interactions

### 4.4 Account Snapshots
- Daily account value tracking
- % deployed calculation
- Month-over-month growth analysis

**Deliverable**: Complete risk management and analytics suite

---

## Milestone 5: Export & Mobile Polish (Week 11-12)
**Goal**: CSV/PDF export, mobile optimization, and final polish

### 5.1 Export Functionality
```ruby
class ReportExportService
  def generate_csv_export(user, options = {})
    # Trade history, performance metrics, watchlists
  end

  def generate_pdf_report(user, report_type, period)
    # Professional reports with charts using Prawn
  end
end
```

### 5.2 PDF Report Generation
- Monthly/quarterly performance reports
- Tax reports (STCG/LTCG classification)
- Trade journal summaries with charts
- Multi-account consolidated reports

### 5.3 Mobile PWA Optimization
- **Performance**: Optimize for Indian mobile networks
- **Touch**: Improve touch targets and gestures
- **PWA**: Service worker for app-like experience
- **Offline**: Basic offline viewing capability

### 5.4 Watchlist Management
- Create multiple custom watchlists
- Price alerts via email/SMS
- Manual stage and RS tracking per stock
- Share functionality (preparation for Phase 2)

### 5.5 Final Polish
- Error handling and loading states
- Performance optimization
- Security audit
- User acceptance testing

**Deliverable**: Complete Phase 1 MVP ready for production

---

## Development Guidelines

### Code Organization
- **Reuse**: Leverage Maybe's existing service patterns
- **Extend**: Follow existing naming conventions
- **Test**: Write RSpec tests following Maybe's patterns
- **Document**: Inline documentation for trading-specific logic

### Database Considerations
- **Indexes**: Optimize for trade queries and time-based lookups
- **Migrations**: Preserve Maybe's existing structure
- **Seeds**: Create sample trading data for development
- **Backup**: Implement regular backup strategy

### Security Requirements
- **API Keys**: Encrypt Zerodha credentials at rest
- **HTTPS**: SSL for all API communications
- **Rate Limiting**: Prevent API abuse
- **Audit**: Log all trade-related actions

### Performance Targets
- **Page Load**: <2 seconds for all pages
- **API Response**: <500ms for portfolio sync
- **Mobile**: 90+ Lighthouse score
- **Database**: <100ms query times

---

## Phase 1 Completion Criteria

### User Acceptance Tests
1. ✅ User can connect multiple Zerodha accounts
2. ✅ Trades import automatically with correct data
3. ✅ Manual trade entry works on mobile and desktop
4. ✅ Journal entries support rich text and images
5. ✅ Position sizing calculator provides accurate results
6. ✅ Performance analytics show meaningful insights
7. ✅ CSV/PDF exports generate professional reports
8. ✅ Watchlists update with live prices
9. ✅ Mobile interface works seamlessly
10. ✅ Application handles 100+ concurrent users

### Technical Validation
- All tests pass (>95% coverage)
- No critical security vulnerabilities
- Performance benchmarks met
- Database optimized for scale
- Error monitoring configured
- Backup and recovery tested

**Target**: Ready for beta user testing and feedback collection for Phase 2 planning

---

## Multi-Tenant Deployment Strategy

### Architecture Decision: Row-Level Multi-Tenancy
- **Implementation**: ActsAsTenant gem with user_id as tenant identifier
- **Data Isolation**: Each user's trades, portfolios, and analysis completely isolated
- **Shared Resources**: Market data (securities, prices) shared across all users
- **Security**: Built-in Rails scoping prevents cross-user data access

### Hosting Platform Progression

#### Phase 1 MVP: Railway Hosting ($15-25/month)
- **Target**: 0-100 beta users
- **Benefits**: Fast Git-based deployments, Rails-native support
- **Features**: Automatic Docker builds, managed PostgreSQL, Sidekiq support
- **Scaling**: Auto-scaling during market hours

#### Phase 2 Growth: Render Hosting ($50-100/month)
- **Target**: 100-1000 users
- **Benefits**: Production-ready infrastructure, predictable pricing
- **Features**: Managed database backups, SSL, CDN, monitoring
- **Migration**: Zero-downtime migration from Railway

#### Phase 3 Scale: DigitalOcean App Platform ($200-500/month)
- **Target**: 1000+ users
- **Benefits**: 50% cost savings vs AWS, financial compliance ready
- **Features**: Multi-region, auto-scaling, advanced monitoring
- **Performance**: Global CDN, optimized for mobile users

### Database Strategy
```ruby
# Multi-tenant model implementation
class Trade < ApplicationRecord
  acts_as_tenant(:user)  # Automatic scoping by current user
  belongs_to :trading_account
  belongs_to :security
end

# Usage in controllers
class TradesController < ApplicationController
  before_action :set_current_tenant

  private

  def set_current_tenant
    ActsAsTenant.current_tenant = current_user
  end
end
```

### Deployment Pipeline
1. **Git Push** → Automatic deployment to staging
2. **Automated Tests** → Full test suite runs
3. **Database Migrations** → Zero-downtime schema updates
4. **Production Deploy** → Rolling deployment with health checks
5. **Monitoring** → Real-time error tracking and performance metrics

### Security & Compliance
- **Data Encryption**: TLS 1.3 in transit, AES-256 at rest
- **API Security**: Encrypted Zerodha credentials, rate limiting
- **Backups**: Daily automated backups with 30-day retention
- **Monitoring**: 24/7 uptime monitoring with alerting
- **Compliance**: SOC 2, ISO 27001 ready for financial regulations

### Cost Optimization
- **MVP**: <$0.25 per user per month
- **Growth**: <$0.10 per user per month
- **Scale**: <$0.20 per user per month
- **Predictable Scaling**: Fixed costs with usage-based scaling