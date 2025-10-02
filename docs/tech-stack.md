# TradeFlow Technology Stack

## Backend Framework

### **Ruby on Rails 7.2.2**
- **Primary Framework**: Web application backbone
- **Why Chosen**: Mature, battle-tested for fintech applications (GitHub, Shopify, Stripe)
- **Benefits**: Rapid development, strong security defaults, excellent for SaaS applications
- **Convention over Configuration**: Reduces development decisions and speeds up delivery

### **PostgreSQL 15+**
- **Primary Database**: All application data storage
- **Provider**: Railway Managed PostgreSQL
- **Why Chosen**: ACID compliance for financial data, excellent Rails integration, proven scalability
- **Features**: JSONB for flexible schemas, full-text search, row-level security for multi-tenancy

### **Redis 7+**
- **Purpose**: Session storage, caching, background job queues
- **Why Chosen**: In-memory performance, battle-tested with Rails, Sidekiq integration
- **Use Cases**: User sessions, API rate limiting, real-time price data caching

## Frontend Stack

### **Inertia.js 1.0+**
- **Purpose**: Single-page application benefits without API complexity
- **Why Chosen**: Modern SPA experience while keeping Rails monolith simplicity
- **Benefits**: No separate frontend build process, shared state management, SEO-friendly

### **Vue.js 3.4+**
- **Purpose**: Frontend JavaScript framework (via Inertia.js)
- **Why Chosen**: Gentle learning curve, excellent documentation, great for data-heavy trading interfaces
- **Alternative**: React also supported by Inertia.js (decision pending based on team preference)

### **Stimulus 3.2+**
- **Purpose**: Progressive enhancement and simple JavaScript interactions
- **Why Chosen**: Rails-native, perfect for form enhancements and real-time updates
- **Use Cases**: Real-time price updates, form validations, interactive charts

### **Tailwind CSS 3.4+**
- **Purpose**: Utility-first CSS framework
- **Why Chosen**: Rapid UI development, consistent design system, mobile-first responsive design
- **Benefits**: Reuse Maybe's existing Tailwind components, easy customization for trading UI

### **Turbo 8+**
- **Purpose**: Fast page navigation and real-time updates
- **Why Chosen**: Native Rails integration, excellent for live data updates during market hours
- **Features**: Turbo Streams for real-time portfolio updates, fast page transitions

## Multi-Tenancy & Security

### **ActsAsTenant 1.0+**
- **Purpose**: Row-level multi-tenancy implementation
- **Why Chosen**: Battle-tested gem, automatic scoping, prevents data leakage between users
- **Security**: Each user's data automatically isolated at database level

### **Devise 4.9+**
- **Purpose**: User authentication and session management
- **Why Chosen**: Industry standard for Rails authentication, supports MFA out of the box
- **Features**: Two-factor authentication, password reset, account locking

### **Pundit 2.3+**
- **Purpose**: Authorization and access control
- **Why Chosen**: Policy-based authorization, easy to understand and maintain
- **Use Cases**: Trading account access, social feature permissions, admin controls

### **User Roles (Simplified String Field)**
- **Current Implementation**: String column with PostgreSQL enum constraint (`'trader'`, `'admin'`)
- **Default Role**: All users default to `'trader'` on registration via ActiveRecord attribute
- **Phase 1 Status**: Field exists but **not actively used** - all users are traders
- **Design Decision**: Using simple string field instead of Rails enum for MVP simplicity
- **Future Use Cases** (Phase 2+):
  - **Admin Dashboard**: Customer support access via Pundit policies checking `user.role == 'admin'`
  - **User Impersonation**: Admin ability to view application from user's perspective
  - **System Monitoring**: Internal analytics, user growth metrics, system health
  - **Content Moderation**: If social features added (shared watchlists, trade ideas)
  - **Subscription Management**: Manual billing adjustments, account management
- **Technical Details**:
  - Database column: `users.role` (PostgreSQL user_role enum type)
  - ActiveRecord: `attribute :role, :string, default: 'trader'`
  - Validation: `validates :role, inclusion: { in: %w[trader admin] }`
  - No Rails enum magic - simple string comparison in code
  - Migration: `db/migrate/000_create_enum_types.rb` (enum exists in DB, used as constraint)
- **Phase 2 Authorization**: Will implement Pundit policies when admin features are needed

## Background Processing

### **Sidekiq 7+**
- **Purpose**: Background job processing
- **Why Chosen**: High performance, Redis-based, excellent Rails integration
- **Use Cases**: Zerodha API sync, price data updates, report generation, email sending

### **Sidekiq-Pro (Future)**
- **Purpose**: Advanced background job features
- **When**: Phase 2+ when scaling beyond hobby tier
- **Features**: Job batching, periodic jobs, enhanced monitoring

## External APIs & Integrations

### **Zerodha Kite Connect API**
- **Purpose**: Portfolio sync, trade import, real-time price data
- **Integration**: Custom service classes wrapping HTTP API
- **Authentication**: OAuth 2.0 with encrypted credential storage

### **OpenAI API 4.0**
- **Purpose**: AI-powered trading insights and analysis
- **Why Kept**: Differentiates from basic trading journals with intelligent analysis
- **Use Cases**: Trade pattern analysis, portfolio insights, strategy recommendations

## Data & Analytics

### **Chart.js 4.4+**
- **Purpose**: Interactive charts and data visualization
- **Why Chosen**: Lightweight, responsive, extensive chart types for trading data
- **Use Cases**: Performance charts, P&L visualization, portfolio allocation charts

### **Ahoy 5+**
- **Purpose**: First-party analytics and user behavior tracking
- **Why Chosen**: Privacy-focused alternative to Google Analytics, Rails-native
- **Data**: Page views, feature usage, user engagement metrics

## File Storage & Assets

### **Active Storage (Rails)**
- **Purpose**: File upload and management
- **Backend**: AWS S3-compatible storage (initially Railway, later S3)
- **Use Cases**: Trade screenshots, chart images, PDF report storage

### **Image Processing**
- **Gem**: image_processing + libvips
- **Purpose**: Resize and optimize uploaded images
- **Use Cases**: Chart screenshot thumbnails, user avatar processing

## Email & Communications

### **Action Mailer (Rails)**
- **Purpose**: Transactional email sending
- **Provider**: SendGrid (Phase 1), later PostMark for higher deliverability
- **Use Cases**: Account verification, password reset, price alerts, trade confirmations

### **Good Job 3.21+**
- **Purpose**: Database-backed job queue (alternative to Sidekiq for simpler deployments)
- **When**: If Redis complexity not needed in MVP
- **Benefits**: PostgreSQL-backed, simpler deployment, built-in web UI

## Development Tools

### **RSpec 3.12+**
- **Purpose**: Testing framework
- **Why Chosen**: BDD approach, excellent Rails integration, comprehensive testing capabilities
- **Coverage**: Unit tests, integration tests, system tests

### **Factory Bot 6.4+**
- **Purpose**: Test data generation
- **Why Chosen**: Clean test data setup, realistic fake trading data for development

### **RuboCop 1.57+**
- **Purpose**: Code quality and style enforcement
- **Configuration**: Standard Ruby style guide + Rails-specific rules
- **Integration**: Pre-commit hooks, CI/CD pipeline checks

### **Bullet 7.1+**
- **Purpose**: N+1 query detection
- **Why Critical**: Trading apps are data-heavy, query optimization essential for performance

## Monitoring & Error Tracking

### **Sentry 5.12+**
- **Purpose**: Error tracking and performance monitoring
- **Why Chosen**: Real-time error alerts, performance insights, release tracking
- **Critical**: Financial applications cannot afford unnoticed errors

### **Skylight 5.3+**
- **Purpose**: Rails performance monitoring
- **Why Chosen**: Rails-specific insights, query performance analysis, endpoint monitoring
- **Use Cases**: Identify slow database queries, optimize trading dashboard performance

## Documentation & API

### **Yard 0.9+**
- **Purpose**: Code documentation generation
- **Why Chosen**: Ruby standard, generates comprehensive API documentation

### **OpenAPI 3.0**
- **Purpose**: API documentation (future when building mobile apps)
- **Implementation**: rswag gem for Rails integration
- **Timeline**: Phase 2 when building native mobile applications

## Security Stack

### **Brakeman 6.0+**
- **Purpose**: Static security analysis for Rails applications
- **Why Critical**: Financial apps require comprehensive security scanning
- **Integration**: CI/CD pipeline, pre-deployment security checks

### **Bundler Audit 0.9+**
- **Purpose**: Check gems for known security vulnerabilities
- **Automation**: Weekly automated scans, dependency update alerts

### **Strong Parameters (Rails)**
- **Purpose**: Parameter filtering and mass assignment protection
- **Why Critical**: Prevents unauthorized data modification in trading records

## Deployment & Infrastructure

### **Phase 1: Railway**
- **Application Hosting**: Railway App Platform
- **Database**: Railway Managed PostgreSQL
- **Cost**: $15-25/month for MVP
- **Benefits**: Simple deployment, Git-based, Rails-optimized

### **Phase 2: Render**
- **Application Hosting**: Render Web Services
- **Database**: Render Managed PostgreSQL
- **Cost**: $50-100/month for growth
- **Benefits**: Production-ready, predictable pricing, advanced monitoring

### **Phase 3: DigitalOcean**
- **Application Hosting**: DigitalOcean App Platform
- **Database**: DigitalOcean Managed PostgreSQL
- **Cost**: $200-500/month for scale
- **Benefits**: Global CDN, auto-scaling, enterprise features

### **Docker 24+**
- **Purpose**: Application containerization
- **Benefits**: Consistent environments, easy deployment, scalability
- **Configuration**: Multi-stage builds, optimized for Rails production

## SSL & Security

### **Let's Encrypt SSL**
- **Purpose**: HTTPS encryption for all traffic
- **Automation**: Automatic certificate renewal
- **Critical**: Required for financial data transmission

### **Content Security Policy (CSP)**
- **Purpose**: XSS attack prevention
- **Implementation**: Rails CSP configuration
- **Requirements**: Strict policy for financial application security

## Performance Stack

### **Bootsnap 1.17+**
- **Purpose**: Reduce Rails application boot time
- **Benefits**: Faster development, quicker deployment cycles

### **Connection Pooling**
- **Database**: PgBouncer for PostgreSQL connection management
- **Redis**: Redis connection pooling for high-concurrency scenarios

### **CDN (Content Delivery Network)**
- **Provider**: CloudFlare (free tier initially)
- **Purpose**: Fast asset delivery globally, DDoS protection
- **Assets**: JavaScript, CSS, images, fonts

## Development Environment

### **Ruby 3.2+**
- **Version Manager**: rbenv or asdf
- **Why This Version**: Performance improvements, latest Rails compatibility

### **Node.js 20+**
- **Purpose**: Frontend asset compilation, JavaScript tooling
- **Package Manager**: npm (bundled with Node.js)

### **Git & GitHub**
- **Version Control**: Git with GitHub repositories
- **Workflow**: Feature branches, pull request reviews, automated deployments

### **VS Code / RubyMine**
- **IDE Recommendations**: Developer preference
- **Extensions**: Ruby, Rails, Tailwind CSS, Docker support

## Third-Party Services (Future)

### **Twilio (Phase 2)**
- **Purpose**: SMS notifications for price alerts
- **Use Cases**: Critical price movement alerts, two-factor authentication

### **SendGrid → PostMark (Phase 2)**
- **Purpose**: Transactional email delivery
- **Migration**: Better deliverability for financial communications

### **Stripe (Phase 2)**
- **Purpose**: Subscription billing for paid plans
- **Integration**: Stripe Billing for recurring revenue management

---

## Technology Decision Rationale

### **Why This Stack Over Alternatives**

**Rails vs Node.js/Python**:
- Faster development with convention over configuration
- Better for solo founder with limited technical resources
- Proven for financial applications (Stripe, GitHub, Shopify)

**PostgreSQL vs MongoDB**:
- ACID compliance essential for financial data
- Better Rails integration and tooling
- Handles both structured trading data and flexible JSON

**Inertia.js vs Pure API + React**:
- Single deployment, simpler architecture
- Shared state between frontend and backend
- Faster development, easier maintenance

**Railway vs AWS/Azure**:
- Simpler deployment and management
- Cost-effective for startup phase
- Clear upgrade path to enterprise platforms

---

## Scaling Considerations

### **Current Stack Handles**:
- 10,000+ concurrent users
- Millions of trades and transactions
- Real-time price updates for 5,000+ securities
- Complex financial calculations and reporting

### **Upgrade Path**:
- **Database**: Read replicas, then sharding if needed
- **Application**: Horizontal scaling with load balancers
- **Cache**: Redis cluster for high availability
- **Infrastructure**: Move to AWS/Azure for enterprise features

This technology stack balances rapid development, proven reliability, and clear scaling path - perfect for a solo founder building a financial technology platform.