# Trading Journal - Complete Specification
## Research-Driven Design for TradeFlow

**Last Updated**: 2025-10-03
**Status**: Design Phase - Pre-Implementation
**Based on**: TraderVue, TradesViz, Edgewonk, StonkJournal research

---

## Executive Summary

TradeFlow's Journal is a **multi-temporal, markdown-powered, AI-assisted trading journal** that goes beyond simple trade notes. It supports:

1. **Temporal Organization**: Daily market reflections, weekly strategy reviews, monthly performance analysis
2. **Trade-Specific Logs**: Per-trade rationale, screenshots, and post-mortems
3. **Learning Library**: Topic-based notes (e.g., "Understanding Stage 2 Breakouts", "My SEPA Setup Criteria")
4. **Feed Curation**: Save important market insights from news feed for future reference
5. **Intelligent Tagging**: Auto-parse stock symbols ($RELIANCE), setups (#Stage2Breakout), and emotions (@FOMO)
6. **Rich Content**: Markdown-powered with images, tables, checklists, and formatted code blocks

---

## Research Insights: What Makes a Great Trading Journal

### Key Findings from Market Leaders

**TraderVue** (Industry Standard, 200K+ traders):
- Separates **per-trade notes** from **daily journal entries**
- Trade notes capture: market conditions, setup reasoning, emotional state
- Daily journal: broader market observations, personal goals, lessons learned
- Strength: Deep analytics integration, automated chart generation
- Weakness: Limited psychology tracking, no rich formatting

**TradesViz** (Feature-Rich, Free Tier):
- 600+ statistics with customizable dashboards
- **Tags at 3 levels**: Trade-level, Day-level, Account-level
- Trading calendar view for temporal organization
- Custom checklists and trade plans
- Strength: Extreme customization, powerful tagging
- Weakness: Overwhelming for beginners, complexity can hinder journaling

**Edgewonk** ($169/year, Psychology Focus):
- **Unique psychology tracking**: Emotional control ratings, concentration levels, plan adherence
- Tracks "trades you didn't take" (missed opportunities)
- Customizable journal templates with 50+ metrics
- Return forecaster based on past performance
- Strength: Best-in-class behavioral analysis
- Weakness: No demo, steep learning curve, Windows-only initially

### Common Patterns Across All Platforms

1. **Temporal Hierarchy**: Trade → Day → Week → Month analysis
2. **Tagging Systems**: Critical for filtering, searching, and pattern recognition
3. **Media Support**: Screenshots are essential (charts before/during/after)
4. **Search & Filter**: Must be able to find entries by symbol, date, strategy, emotion
5. **Templates**: Pre-built checklists for consistency (SEPA criteria, Stage 2 checklist, etc.)

### What TradeFlow Will Do Better

1. **Markdown-First**: Unlike competitors (all use proprietary editors), we use Markdown for:
   - Portability (plain text, exportable anywhere)
   - Familiarity (traders already know Markdown from GitHub, Notion, Obsidian)
   - Power (tables, code blocks, LaTeX for formulas)
   - Speed (no WYSIWYG lag)

2. **Unified Journal**: One place for trade notes, daily reflections, learning notes, feed saves
   - Competitors force separation (trade notes vs. daily journal)
   - TradeFlow uses **entry types** with intelligent filtering

3. **AI-Assisted Parsing**: Auto-detect symbols, setups, emotions without manual tagging
   - Type `$RELIANCE` → auto-linked to security, searchable, charted
   - Type `#Stage2Breakout` → auto-tagged as setup, filterable
   - Type `@FOMO` → auto-tagged as emotion, behavioral analytics

4. **Learning Library**: Capture reusable knowledge, not just trade logs
   - "My SEPA Checklist" → reference in future trades
   - "Understanding Weinstein Stage Analysis" → evolving notes
   - "Zerodha API Integration Lessons" → technical documentation

---

## Journal Architecture

### Entry Types (Primary Classification)

Every journal entry has a **type** that determines structure and organization:

| Type | Purpose | Template | Linking | Examples |
|------|---------|----------|---------|----------|
| **Trade Note** | Document rationale for a specific trade | SEPA checklist, Stage 2 criteria | Linked to Trade record | Entry rationale, exit analysis |
| **Daily Log** | End-of-day market reflection | Daily reflection template | Linked to date | Market observations, emotions |
| **Weekly Review** | Strategic review of week's performance | Weekly review template | Linked to week | What worked, what didn't |
| **Monthly Report** | Comprehensive performance analysis | Monthly metrics template | Linked to month | Goal progress, key lessons |
| **Learning Note** | Evergreen knowledge on a topic | Topic-based template | Standalone, tagged | "My SEPA Setup Criteria" |
| **Feed Save** | Important insight from market feed | Minimal (quote + commentary) | Linked to NewsItem | Saved Bloomberg article |
| **Watchlist Note** | Analysis for stock on watchlist | Setup analysis template | Linked to Security | "Why I'm watching RELIANCE" |

### Temporal Hierarchy

```
Year 2025
├── Q1 2025
│   ├── January 2025 (Monthly Report)
│   │   ├── Week 1 (Jan 1-7) (Weekly Review)
│   │   │   ├── 2025-01-03 (Daily Log)
│   │   │   │   ├── Trade #1: RELIANCE Long (Trade Note)
│   │   │   │   ├── Trade #2: TCS Short (Trade Note)
│   │   │   │   └── Daily Reflection (Daily Log)
│   │   │   ├── 2025-01-04 (Daily Log)
│   │   │   └── ...
│   │   ├── Week 2 (Jan 8-14) (Weekly Review)
│   │   └── ...
│   ├── February 2025 (Monthly Report)
│   └── March 2025 (Monthly Report)
└── ...

Learning Library (Non-temporal)
├── "Understanding Stage 2 Breakouts" (Learning Note)
├── "My SEPA Checklist v3.2" (Learning Note)
└── "Emotional Trading Patterns I've Noticed" (Learning Note)
```

---

## Data Model

### Core Tables

#### 1. `journal_entries` (Main Entry Table)

```sql
CREATE TABLE journal_entries (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Entry Classification
  entry_type VARCHAR NOT NULL, -- 'trade_note', 'daily_log', 'weekly_review', 'monthly_report', 'learning_note', 'feed_save', 'watchlist_note'
  entry_subtype VARCHAR, -- User-defined subcategory (e.g., 'mistake_analysis', 'breakthrough_moment')

  -- Content (Markdown-powered)
  title VARCHAR(200) NOT NULL, -- "RELIANCE Stage 2 Entry Analysis"
  content TEXT NOT NULL, -- Full markdown content
  content_html TEXT, -- Rendered HTML (cached, regenerated on save)
  excerpt TEXT, -- First 200 chars for previews (auto-generated)

  -- Temporal Links
  entry_date DATE NOT NULL, -- Date this entry is associated with
  week_start_date DATE, -- Computed: Monday of that week (for weekly reviews)
  month_start_date DATE, -- Computed: First day of that month (for monthly reports)

  -- Relational Links
  trade_id BIGINT REFERENCES trades(id) ON DELETE SET NULL, -- If linked to specific trade
  security_id BIGINT REFERENCES securities(id) ON DELETE SET NULL, -- If analyzing specific stock
  market_news_item_id BIGINT REFERENCES market_news_items(id) ON DELETE SET NULL, -- If saving from feed
  parent_entry_id BIGINT REFERENCES journal_entries(id) ON DELETE CASCADE, -- For threaded notes (replies)

  -- Metadata
  is_template BOOLEAN DEFAULT FALSE, -- True if this is a reusable template
  is_pinned BOOLEAN DEFAULT FALSE, -- Pin to top of journal
  is_private BOOLEAN DEFAULT TRUE, -- Private vs. shareable (Phase 3: social)
  word_count INTEGER DEFAULT 0, -- Computed on save
  reading_time_minutes INTEGER DEFAULT 0, -- Computed on save (word_count / 200)

  -- Searchability
  search_vector TSVECTOR, -- Full-text search (PostgreSQL)

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  published_at TIMESTAMP, -- NULL if draft, timestamp if published

  INDEX idx_user_date (user_id, entry_date DESC),
  INDEX idx_user_type (user_id, entry_type),
  INDEX idx_trade (trade_id),
  INDEX idx_security (security_id),
  INDEX idx_temporal (entry_date, week_start_date, month_start_date),
  INDEX idx_search (search_vector) USING GIN,

  CONSTRAINT valid_entry_type CHECK (entry_type IN (
    'trade_note', 'daily_log', 'weekly_review', 'monthly_report',
    'learning_note', 'feed_save', 'watchlist_note'
  ))
);
```

#### 2. `journal_tags` (Auto-parsed and Manual Tags)

```sql
CREATE TABLE journal_tags (
  id BIGSERIAL PRIMARY KEY,
  journal_entry_id BIGINT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,

  -- Tag Classification
  tag_type VARCHAR NOT NULL, -- 'symbol', 'setup', 'emotion', 'strategy', 'mistake', 'custom'
  tag_value VARCHAR(100) NOT NULL, -- 'RELIANCE', 'Stage2Breakout', 'FOMO', 'RevengeTrade'

  -- Auto-detection Metadata
  is_auto_parsed BOOLEAN DEFAULT FALSE, -- Auto-detected vs. manually added
  occurrence_count INTEGER DEFAULT 1, -- How many times mentioned in entry
  first_occurrence_position INTEGER, -- Character position of first mention

  -- Relational Links (for symbol tags)
  security_id BIGINT REFERENCES securities(id) ON DELETE CASCADE, -- If tag is a stock symbol

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_entry (journal_entry_id),
  INDEX idx_type_value (tag_type, tag_value),
  INDEX idx_security (security_id),
  UNIQUE INDEX idx_unique_tag_per_entry (journal_entry_id, tag_type, tag_value),

  CONSTRAINT valid_tag_type CHECK (tag_type IN (
    'symbol', 'setup', 'emotion', 'strategy', 'mistake', 'custom'
  ))
);
```

#### 3. `journal_media` (Images, Screenshots, Attachments)

```sql
CREATE TABLE journal_media (
  id BIGSERIAL PRIMARY KEY,
  journal_entry_id BIGINT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,

  -- Media Classification
  media_type VARCHAR NOT NULL, -- 'image', 'chart_screenshot', 'document', 'video' (future)
  media_role VARCHAR, -- 'entry_chart', 'exit_chart', 'setup_annotation', 'reference'

  -- File Storage (Active Storage)
  file_path VARCHAR NOT NULL, -- S3 or local storage path
  filename VARCHAR NOT NULL,
  content_type VARCHAR NOT NULL, -- 'image/png', 'image/jpeg', 'application/pdf'
  file_size_bytes BIGINT NOT NULL,

  -- Image Metadata (for images only)
  width_px INTEGER,
  height_px INTEGER,
  thumbnail_path VARCHAR, -- Smaller version for previews

  -- Display Metadata
  caption TEXT, -- User-provided caption
  alt_text VARCHAR(200), -- Accessibility description
  display_order INTEGER DEFAULT 0, -- Order in entry (0 = first image)

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_entry (journal_entry_id),
  INDEX idx_type (media_type)
);
```

#### 4. `journal_templates` (Reusable Templates)

```sql
CREATE TABLE journal_templates (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE, -- NULL for system templates

  -- Template Identification
  template_name VARCHAR(100) NOT NULL, -- "SEPA Checklist", "Weekly Review"
  template_type VARCHAR NOT NULL, -- Maps to entry_type

  -- Template Content
  template_content TEXT NOT NULL, -- Markdown template with placeholders
  description TEXT, -- What this template is for

  -- Metadata
  is_system_template BOOLEAN DEFAULT FALSE, -- Built-in vs. user-created
  is_public BOOLEAN DEFAULT FALSE, -- Shareable with community (Phase 3)
  usage_count INTEGER DEFAULT 0, -- How many times used

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_user (user_id),
  INDEX idx_type (template_type)
);
```

#### 5. `journal_checklists` (Interactive Checklists within Entries)

```sql
CREATE TABLE journal_checklists (
  id BIGSERIAL PRIMARY KEY,
  journal_entry_id BIGINT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,

  -- Checklist Metadata
  checklist_name VARCHAR(100), -- "SEPA Criteria", "Stage 2 Validation"
  display_order INTEGER DEFAULT 0,

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_entry (journal_entry_id)
);

CREATE TABLE journal_checklist_items (
  id BIGSERIAL PRIMARY KEY,
  journal_checklist_id BIGINT NOT NULL REFERENCES journal_checklists(id) ON DELETE CASCADE,

  -- Checklist Item
  item_text VARCHAR(500) NOT NULL, -- "Pocket pivot on increasing volume"
  is_checked BOOLEAN DEFAULT FALSE,
  is_critical BOOLEAN DEFAULT FALSE, -- Must be checked (validation)
  display_order INTEGER DEFAULT 0,

  -- Optional Metadata
  checked_at TIMESTAMP, -- When user checked this item
  notes TEXT, -- User notes on why checked/unchecked

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_checklist (journal_checklist_id)
);
```

---

## Intelligent Tagging System

### Auto-Parsing Rules (Applied on Save)

TradeFlow automatically detects and tags content using regex patterns:

#### 1. **Symbol Tags** (`$SYMBOL` format)

**Pattern**: `\$([A-Z0-9]{1,10})\b`

**Examples**:
- `$RELIANCE` → Tag: {type: 'symbol', value: 'RELIANCE', security_id: 123}
- `$TATAMOTORS` → Tag: {type: 'symbol', value: 'TATAMOTORS', security_id: 456}
- `Bought $INFY at 1500` → Auto-linked to INFY security page

**Behavior**:
- Look up symbol in `securities` table
- If found: Create tag with `security_id` link
- If not found: Create tag but flag for user verification
- Render as clickable link in HTML: `<a href="/securities/RELIANCE">$RELIANCE</a>`
- Show inline mini-chart on hover (Phase 2)

#### 2. **Setup Tags** (`#SetupName` format)

**Pattern**: `#([A-Za-z0-9_]+)`

**Examples**:
- `#Stage2Breakout` → Tag: {type: 'setup', value: 'Stage2Breakout'}
- `#SEPAEntry` → Tag: {type: 'setup', value: 'SEPAEntry'}
- `Used my #PocketPivot setup` → Auto-tagged

**Behavior**:
- Extract setup name (camelCase or snake_case)
- Create tag with type 'setup'
- Render as styled badge in HTML: `<span class="badge badge-setup">#Stage2Breakout</span>`
- Link to analytics: "Show all trades with #Stage2Breakout setup"

#### 3. **Emotion Tags** (`@Emotion` format)

**Pattern**: `@([A-Za-z]+)`

**Examples**:
- `@FOMO` → Tag: {type: 'emotion', value: 'FOMO'}
- `@Confident` → Tag: {type: 'emotion', value: 'Confident'}
- `Felt @Anxious about the position size` → Auto-tagged

**Predefined Emotions** (validated against list):
- Positive: `@Confident`, `@Calm`, `@Disciplined`, `@Patient`
- Negative: `@FOMO`, `@Fear`, `@Greed`, `@Revenge`, `@Panic`, `@Regret`
- Neutral: `@Uncertain`, `@Observant`, `@Analytical`

**Behavior**:
- Validate against predefined list (or create new if not exists)
- Create tag with type 'emotion'
- Aggregate for behavioral analytics (Edgewonk-style)
- Render with emotion-specific color: `<span class="badge badge-emotion-negative">@FOMO</span>`

#### 4. **Strategy Tags** (`/Strategy` format - optional)

**Pattern**: `/([A-Za-z0-9_]+)`

**Examples**:
- `/Momentum` → Tag: {type: 'strategy', value: 'Momentum'}
- `/OptionsWheel` → Tag: {type: 'strategy', value: 'OptionsWheel'}

**Behavior**:
- Similar to setup tags but broader category
- Links to strategy performance analytics

#### 5. **Mistake Tags** (`!Mistake` format)

**Pattern**: `!([A-Za-z0-9_]+)`

**Examples**:
- `!EnteredTooEarly` → Tag: {type: 'mistake', value: 'EnteredTooEarly'}
- `!IgnoredStopLoss` → Tag: {type: 'mistake', value: 'IgnoredStopLoss'}

**Behavior**:
- Tracks common mistakes for pattern recognition
- Feeds into improvement tracking (Edgewonk-style)
- Shows mistake frequency over time

### Manual Tagging UI

In addition to auto-parsing, users can manually add tags:

**Tag Input Component** (below markdown editor):
```
Tags: [+Add Tag ▼]

Selected Tags:
[× RELIANCE (symbol)] [× Stage2Breakout (setup)] [× FOMO (emotion)]
```

**Dropdown**:
- Recent tags (last 20 used)
- Popular tags (most frequently used)
- Create new custom tag

---

## Markdown Editor

### Editor Features

**Live Preview** (Split-pane or toggle):
- Left: Raw Markdown
- Right: Rendered HTML preview
- Sync scroll position

**Syntax Highlighting**:
- Stock symbols: `$RELIANCE` in blue
- Setup tags: `#Stage2Breakout` in green
- Emotion tags: `@FOMO` in red/yellow
- Standard Markdown: headers, bold, italic, links, etc.

**Toolbar** (optional, for Markdown beginners):
```
[B] [I] [H1] [H2] [Link] [Image] [List] [Table] [Checklist] [Code]
```

**Auto-Save**:
- Save draft every 30 seconds
- Restore from draft on page load
- Show "Saving..." indicator

**Keyboard Shortcuts**:
- `Cmd/Ctrl + B` - Bold
- `Cmd/Ctrl + I` - Italic
- `Cmd/Ctrl + K` - Insert link
- `Cmd/Ctrl + S` - Save entry
- `Cmd/Ctrl + Enter` - Publish entry

### Supported Markdown Syntax

**Standard Markdown**:
```markdown
# Heading 1
## Heading 2
### Heading 3

**Bold text**
*Italic text*
~~Strikethrough~~

- Unordered list
1. Ordered list

[Link text](https://example.com)
![Image alt text](image.jpg)

> Blockquote

`Inline code`

```python
# Code block with syntax highlighting
def calculate_position_size(risk, stop):
    return risk / stop
```

| Symbol | Entry | Exit | P&L |
|--------|-------|------|-----|
| RELIANCE | 2500 | 2600 | +4% |
```

**Extended Syntax** (GitHub Flavored Markdown):
```markdown
- [ ] Unchecked task
- [x] Checked task

==Highlighted text==

~~Strikethrough~~

Footnote[^1]
[^1]: Footnote content
```

**TradeFlow-Specific Extensions**:
```markdown
$RELIANCE → Auto-linked stock symbol
#Stage2Breakout → Auto-tagged setup
@FOMO → Auto-tagged emotion

[chart:RELIANCE:1D] → Embed live chart (Phase 2)
[trade:123] → Embed trade summary card
```

### Image Upload

**Drag-and-Drop**:
- Drag image into editor → Upload to storage → Insert markdown
- `![Entry chart for RELIANCE](https://storage.../chart1.png)`

**Paste from Clipboard**:
- Screenshot → Paste into editor → Auto-upload → Insert markdown

**Image Annotation** (Phase 2):
- Click image in preview → Open annotation tool
- Draw arrows, text, highlights
- Save annotated version

---

## Entry Templates

### System Templates (Pre-built)

#### 1. **Trade Note Template** (SEPA Checklist Example)

```markdown
# Trade Entry: $SYMBOL

## Setup Analysis
- **Date**: YYYY-MM-DD
- **Strategy**: #SEPAEntry
- **Stage**: [ ] 1  [ ] 2  [ ] 3  [ ] 4
- **RS Rank**: ___ / 10

## SEPA Checklist
- [ ] Stock in Stage 2 uptrend
- [ ] Pocket pivot on volume 40%+ above avg
- [ ] RS line at or near new highs
- [ ] 50-day MA rising
- [ ] Above 200-day MA
- [ ] Tight base (< 15% depth)

## Entry Rationale
_Why am I entering this trade?_

## Risk Management
- **Entry Price**: ₹___
- **Stop Loss**: ₹___
- **Target**: ₹___
- **Position Size**: ___ shares
- **Risk Amount**: ₹___
- **Risk %**: ___ % of account
- **R-Multiple Target**: ___R

## Entry Chart
![Entry Chart](upload_chart_here)

## Emotional State
Feeling: @___
Confidence (1-5): ___
```

#### 2. **Daily Log Template**

```markdown
# Daily Journal: YYYY-MM-DD

## Market Overview
**Indices**: NIFTY ___ (___%), BANKNIFTY ___ (___%)
**Market Condition**: [ ] Bull  [ ] Bear  [ ] Neutral  [ ] Choppy

## Trades Today
1. $SYMBOL1 - [Result]
2. $SYMBOL2 - [Result]

## What Went Well
-

## What Went Wrong
-

## Lessons Learned
-

## Emotional State
Overall mood: @___
Energy level (1-5): ___
Discipline score (1-5): ___

## Tomorrow's Plan
-
```

#### 3. **Weekly Review Template**

```markdown
# Weekly Review: Week of MMM DD, YYYY

## Performance Summary
- **Total Trades**: ___
- **Win Rate**: ___% (___ wins / ___ losses)
- **P&L**: ₹___ (___%)
- **Average R**: ___R
- **Best Trade**: $SYMBOL (___R)
- **Worst Trade**: $SYMBOL (___R)

## Strategy Performance
| Strategy | Trades | Win Rate | Avg R | Total P&L |
|----------|--------|----------|-------|-----------|
| #Stage2Breakout | | | | |
| #SEPAEntry | | | | |

## What Worked This Week
1.
2.
3.

## What Didn't Work
1.
2.
3.

## Key Lessons
-

## Behavioral Observations
- Emotional patterns noticed:
- Discipline adherence (1-5): ___
- Mistakes made: !___

## Next Week's Focus
1.
2.
3.

## Goals for Next Week
- [ ] Goal 1
- [ ] Goal 2
- [ ] Goal 3
```

#### 4. **Monthly Report Template**

```markdown
# Monthly Report: MMMM YYYY

## Executive Summary
**Overall P&L**: ₹___ (___%)
**Total Trades**: ___
**Win Rate**: ___%
**Best Month?** [ ] Yes  [ ] No
**Account Growth**: ___%

## Performance Metrics
- **Profit Factor**: ___
- **Average R**: ___R
- **Max Drawdown**: ___%
- **Sharpe Ratio**: ___
- **Best Trade**: $SYMBOL (___R, ₹___)
- **Worst Trade**: $SYMBOL (___R, ₹___)

## Strategy Analysis
| Strategy | Trades | Win Rate | Avg R | Total P&L |
|----------|--------|----------|-------|-----------|
| | | | | |

## Stage Analysis
| Stage | Trades | Win Rate | Avg R | Notes |
|-------|--------|----------|-------|-------|
| Stage 1 | | | | |
| Stage 2 | | | | |
| Stage 3 | | | | |
| Stage 4 | | | | |

## Behavioral Report
- **Most common emotion**: @___
- **Discipline score**: ___ / 5
- **Mistakes made**: ___ (down from ___ last month)
- **Rule violations**: ___ times

## Top 3 Wins
1.
2.
3.

## Top 3 Losses
1.
2.
3.

## Key Learnings This Month
1.
2.
3.

## Areas for Improvement
1.
2.
3.

## Goals for Next Month
- [ ]
- [ ]
- [ ]

## Notes & Observations
```

#### 5. **Learning Note Template**

```markdown
# Topic: [Title]

**Category**: #___
**Date Created**: YYYY-MM-DD
**Last Updated**: YYYY-MM-DD

## Overview
_Brief summary of this topic_

## Key Concepts
1.
2.
3.

## My Understanding
_Explain in your own words_

## Examples
### Example 1: $SYMBOL
_Describe the example_

### Example 2: $SYMBOL
_Describe the example_

## Checklist / Criteria
- [ ]
- [ ]
- [ ]

## Common Mistakes to Avoid
1. !___
2. !___

## Related Topics
- [[Link to other learning note]]
- [[Link to other learning note]]

## References
- [External resource](URL)
- Trade #123 - practical example

## Personal Notes
_Your evolving thoughts on this topic_
```

### Custom Templates

**User can create custom templates**:
1. Write a journal entry with desired structure
2. Click "Save as Template"
3. Name the template
4. Template available in "New Entry" dropdown

**Template Variables** (optional, Phase 2):
```markdown
{{SYMBOL}} → Prompt user for symbol when using template
{{DATE}} → Auto-fill current date
{{ENTRY_PRICE}} → Pull from linked trade
```

---

## Journal UI/UX

### Journal Index Page (`/journal`)

**Layout**: 3-column design

#### Left Sidebar (200px): **Filters & Navigation**

```
[+ New Entry ▼]

📅 Temporal
├── Today
├── This Week
├── This Month
├── Custom Range...

📁 Entry Types
├── All Entries
├── Trade Notes (42)
├── Daily Logs (30)
├── Weekly Reviews (4)
├── Monthly Reports (1)
├── Learning Notes (12)
├── Feed Saves (8)
└── Templates

🏷️ Tags
├── Symbols (15)
│   ├── $RELIANCE (8)
│   ├── $INFY (5)
│   └── View all...
├── Setups (6)
│   ├── #Stage2Breakout (12)
│   ├── #SEPAEntry (8)
│   └── View all...
├── Emotions (5)
│   ├── @FOMO (3)
│   ├── @Confident (10)
│   └── View all...
└── Custom (2)

🔖 Saved
├── Pinned (3)
├── Drafts (2)
└── Templates (5)

🔍 Search
[Search journal...]
```

#### Center Panel (fluid): **Entry List**

**View Options**:
```
[List View] [Card View] [Calendar View]
Sort: [Newest First ▼]
```

**List View** (default):
```
┌─────────────────────────────────────────┐
│ 📝 RELIANCE Stage 2 Entry Analysis      │
│ Trade Note • Jan 3, 2025 • 5 min read  │
│ Tags: $RELIANCE #Stage2Breakout @Confident │
│ ─────────────────────────────────────── │
│ Entered RELIANCE after seeing pocket    │
│ pivot on strong volume. All SEPA        │
│ criteria met. Feeling confident...      │
│ ─────────────────────────────────────── │
│ 📎 2 images  💬 0 comments  ⭐ Pinned   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 📆 Daily Journal: Jan 3, 2025           │
│ Daily Log • Jan 3, 2025 • 3 min read   │
│ Tags: @Disciplined                      │
│ ─────────────────────────────────────── │
│ Great day overall. Market cooperated.   │
│ Stuck to my plan and avoided FOMO...    │
│ ─────────────────────────────────────── │
│ 💬 1 comment (from mentor)              │
└─────────────────────────────────────────┘
```

**Card View**:
- Grid layout (2-3 columns depending on screen width)
- Larger thumbnails
- Less text preview

**Calendar View** (Phase 2):
- Monthly calendar
- Dots on dates with entries
- Color-coded by entry type
- Click date → show entries for that day

#### Right Sidebar (300px): **Entry Preview / Details**

When entry selected from list:

```
┌──────────────────────────────────────┐
│  RELIANCE Stage 2 Entry Analysis     │
│  ─────────────────────────────────   │
│  Type: Trade Note                    │
│  Date: Jan 3, 2025                   │
│  Updated: Jan 4, 2025 3:45 PM        │
│                                       │
│  Linked To:                          │
│  • Trade #123 (RELIANCE Long)        │
│  • Security: RELIANCE                │
│                                       │
│  Tags:                               │
│  [$RELIANCE] [#Stage2Breakout]      │
│  [@Confident]                        │
│                                       │
│  Stats:                              │
│  • 487 words                         │
│  • 5 min read                        │
│  • 2 images                          │
│  • 1 checklist (6/6 items)           │
│                                       │
│  Actions:                            │
│  [Edit] [Delete] [Pin] [Share]      │
│  [Export PDF]                        │
└──────────────────────────────────────┘
```

---

### Journal Entry View/Edit Page (`/journal/:id`)

**Layout**: Full-width, focus mode

#### Top Bar (sticky)

```
[← Back to Journal]                    [Preview] [Save Draft] [Publish]

Entry Type: [Trade Note ▼]  Date: [Jan 3, 2025]  Template: [SEPA Entry ▼]
```

#### Main Editor (centered, max-width 900px)

```
┌────────────────────────────────────────────────┐
│  Title: [Entry title here]                    │
│  ──────────────────────────────────────────── │
│                                                 │
│  [Markdown Toolbar]                            │
│  [B] [I] [H] [Link] [Image] [List] [Table]    │
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │ # Trade Entry: $RELIANCE                │  │
│  │                                          │  │
│  │ ## Setup Analysis                       │  │
│  │ - **Date**: 2025-01-03                  │  │
│  │ - **Strategy**: #Stage2Breakout         │  │
│  │ - **Stage**: [x] 2                      │  │
│  │                                          │  │
│  │ ## SEPA Checklist                       │  │
│  │ - [x] Stock in Stage 2 uptrend          │  │
│  │ - [x] Pocket pivot on volume 40%+       │  │
│  │                                          │  │
│  │ Feeling @Confident about this trade.    │  │
│  │                                          │  │
│  │ ![Entry chart](chart1.png)              │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  ──────────────────────────────────────────── │
│  Tags: [$RELIANCE] [#Stage2Breakout] [@Confident] [+Add Tag]
│                                                 │
│  Link to: Trade #___ | Security: [RELIANCE ▼]  │
│                                                 │
│  Attachments: [📎 Drag files or click to upload]
│  • chart1.png (245 KB) [✓] [Delete]            │
│  • exit_analysis.png (189 KB) [✓] [Delete]     │
└────────────────────────────────────────────────┘

[Save Draft]  [Publish Entry]  [Delete]
```

**Preview Mode** (toggle):
- Full markdown rendered
- Looks exactly like final published view
- Toggle back to edit mode

---

## Search & Discovery

### Global Journal Search

**Search Bar** (top of journal page):
```
[🔍 Search journal entries, tags, symbols...            ]

Filters: [All Types ▼] [All Tags ▼] [Date Range ▼]
```

**Search Features**:
1. **Full-text search** (PostgreSQL `tsvector`)
2. **Tag search**: `tag:Stage2Breakout` or `#Stage2Breakout`
3. **Symbol search**: `symbol:RELIANCE` or `$RELIANCE`
4. **Emotion search**: `emotion:FOMO` or `@FOMO`
5. **Date range**: `date:2025-01` or `date:last_week`
6. **Entry type**: `type:trade_note` or `type:daily_log`

**Search Examples**:
- `$RELIANCE #Stage2Breakout` → All Stage 2 breakout entries for RELIANCE
- `@FOMO !EnteredTooEarly` → Entries where I felt FOMO and made mistake
- `type:weekly_review date:2025-01` → All weekly reviews from January 2025
- `checklist:incomplete` → Entries with incomplete checklists (Phase 2)

**Search Results**:
- Highlight matching text
- Show context (2 lines before/after match)
- Group by entry type or date
- Sort by relevance or date

---

## Special Features

### 1. **Feed Save** (Save from Market Feed)

**User Flow**:
1. User sees interesting news item in Feed page
2. Clicks "Save to Journal" button
3. Modal opens:
   ```
   ┌────────────────────────────────────┐
   │  Save to Journal                   │
   │  ──────────────────────────────    │
   │  News: "Fed signals rate cuts..."  │
   │  Source: Bloomberg                 │
   │                                     │
   │  Add your commentary:              │
   │  ┌────────────────────────────┐   │
   │  │ This could impact my       │   │
   │  │ positions in $RELIANCE and │   │
   │  │ $INFY. Need to watch...    │   │
   │  └────────────────────────────┘   │
   │                                     │
   │  Tags: [$RELIANCE] [$INFY] [+]     │
   │                                     │
   │  [Cancel]  [Save to Journal]       │
   └────────────────────────────────────┘
   ```
4. Saved entry appears in Journal with type `feed_save`
5. Entry includes:
   - Original news headline + link
   - User's commentary
   - Auto-tags from commentary
   - Link to original NewsItem record

**Benefit**: Curate market insights without leaving feed, reference later

---

### 2. **Learning Library** (Non-Temporal Knowledge)

**Purpose**: Store evergreen trading knowledge separate from daily logs

**Example Use Cases**:
- "My SEPA Setup Criteria" (evolving checklist)
- "Understanding Weinstein Stage Analysis" (reference guide)
- "Zerodha API Quirks I've Learned" (technical notes)
- "Emotional Patterns I've Noticed" (self-awareness)

**Features**:
- Entry type: `learning_note`
- Not tied to specific date (or creation date only)
- Can link to trades as examples
- Can include checklists, tables, code blocks
- Can version-control (Phase 2: show edit history)

**Organization**:
- Tag-based (not date-based)
- Can create "table of contents" entry linking to all notes
- Can pin important notes to top of library

---

### 3. **Watchlist Note** (Stock Analysis)

**User Flow**:
1. User adds stock to watchlist
2. Clicks "Add Analysis" on watchlist item
3. Opens journal editor with:
   - Entry type: `watchlist_note`
   - Linked to: Security (e.g., RELIANCE)
   - Template: "Stock Analysis Template"

**Template**:
```markdown
# Watchlist Analysis: $SYMBOL

## Why I'm Watching
_Brief rationale_

## Stage Analysis
Current Stage: [ ] 1  [ ] 2  [ ] 3  [ ] 4
Stage Notes: _Your analysis_

## Relative Strength
RS Rank: ___ / 10
RS Notes: _Your analysis_

## Setup Checklist
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Entry Plan
- **Target Entry**: ₹___
- **Stop Loss**: ₹___
- **Position Size**: ___ shares
- **Risk**: ₹___ (___%)

## Chart
![Setup chart](upload_here)

## Notes
_Additional observations_
```

**Benefit**: Keep detailed analysis per stock, reference when ready to enter

---

### 4. **Checklists** (Interactive within Entries)

**Markdown Syntax**:
```markdown
- [ ] Unchecked item
- [x] Checked item
```

**Enhanced Checklist Features**:
- **Progress Indicator**: "4/6 items complete" (auto-calculated)
- **Critical Items**: Mark checklist items as "must-check" for validation
- **Completion Tracking**: Store `checked_at` timestamp per item
- **Checklist Templates**: Reusable (e.g., "SEPA Criteria", "Weinstein Stage 2")

**UI**:
```
┌────────────────────────────────────┐
│  SEPA Checklist (5/6 complete)     │
│  ──────────────────────────────    │
│  ☑ Stock in Stage 2 uptrend        │
│  ☑ Pocket pivot on volume 40%+     │
│  ☑ RS line at new highs            │
│  ☑ 50-day MA rising                │
│  ☑ Above 200-day MA                │
│  ☐ Tight base (< 15% depth) ⚠      │
│  ──────────────────────────────    │
│  ⚠ 1 critical item unchecked       │
└────────────────────────────────────┘
```

**Validation** (Phase 2):
- If checklist has critical items unchecked, warn before closing trade
- "You didn't validate tight base criteria. Are you sure?"

---

### 5. **Linked Entries** (Trade → Journal → Analysis)

**Bidirectional Links**:

**From Trade Page** (`/trades/123`):
```
┌────────────────────────────────────┐
│  Trade #123: RELIANCE Long         │
│  ──────────────────────────────    │
│  Entry: ₹2500  Exit: ₹2600         │
│  P&L: +4% (+₹10,000)               │
│  ──────────────────────────────    │
│  📝 Journal Entries (2)            │
│  • Entry Analysis (Jan 3)  [View]  │
│  • Exit Review (Jan 10)    [View]  │
│  ──────────────────────────────    │
│  [+ Add Journal Entry]             │
└────────────────────────────────────┘
```

**From Journal Entry** (`/journal/456`):
```
┌────────────────────────────────────┐
│  Linked Trade: #123                │
│  RELIANCE Long • +4% • ₹10,000     │
│  Jan 3 - Jan 10 (7 days)           │
│  [View Full Trade Details →]       │
└────────────────────────────────────┘
```

**Benefit**: Seamless navigation between trade data and analysis

---

## Analytics & Insights (Phase 2)

### Journal Analytics Dashboard

**Metrics to Track**:
1. **Journaling Consistency**:
   - Streak: "15 days in a row with journal entries"
   - Coverage: "42/45 trades have journal entries (93%)"
   - Word count over time (trend chart)

2. **Tag Analytics**:
   - Most common setups: #Stage2Breakout (12), #SEPAEntry (8)
   - Most common emotions: @Confident (10), @FOMO (3)
   - Most analyzed symbols: $RELIANCE (8), $INFY (5)

3. **Behavioral Insights** (Edgewonk-style):
   - Emotion → Performance correlation
     - Trades with @Confident: 80% win rate
     - Trades with @FOMO: 30% win rate
   - Checklist completion → Performance
     - 6/6 checklist items: 85% win rate
     - <4/6 checklist items: 45% win rate

4. **Learning Progress**:
   - Learning notes created: 12
   - Topics covered: Stage analysis (3), SEPA (2), Psychology (4)
   - Most referenced learning note: "My SEPA Criteria"

---

## Technical Implementation

### Markdown Processing Pipeline

**Server-Side (Rails)**:
```ruby
class JournalEntry < ApplicationRecord
  before_save :process_markdown
  after_save :extract_tags

  def process_markdown
    # 1. Parse Markdown to HTML
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      filter_html: false,
      safe_links_only: true
    )
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      footnotes: true,
      quote: true,
      no_intra_emphasis: true
    )

    self.content_html = markdown.render(content)

    # 2. Auto-link symbols, setups, emotions
    self.content_html = auto_link_tags(content_html)

    # 3. Generate excerpt (first 200 chars, strip HTML)
    self.excerpt = ActionView::Base.full_sanitizer.sanitize(content_html)[0..200]

    # 4. Calculate word count and reading time
    self.word_count = content.split.size
    self.reading_time_minutes = (word_count / 200.0).ceil

    # 5. Update full-text search vector
    self.search_vector = "#{title} #{content}".to_tsvector
  end

  def extract_tags
    # Auto-parse tags from content
    TagExtractionService.new(self).extract_and_create_tags
  end

  private

  def auto_link_tags(html)
    # Symbol tags: $RELIANCE
    html.gsub(/\$([A-Z0-9]{1,10})\b/) do |match|
      symbol = $1
      security = Security.find_by(symbol: symbol)
      if security
        "<a href='/securities/#{security.id}' class='tag-symbol'>#{match}</a>"
      else
        "<span class='tag-symbol-unknown'>#{match}</span>"
      end
    end

    # Setup tags: #Stage2Breakout
    html.gsub(/#([A-Za-z0-9_]+)/) do |match|
      "<span class='tag-setup'>#{match}</span>"
    end

    # Emotion tags: @FOMO
    html.gsub(/@([A-Za-z]+)/) do |match|
      "<span class='tag-emotion'>#{match}</span>"
    end
  end
end
```

**Tag Extraction Service**:
```ruby
class TagExtractionService
  def initialize(journal_entry)
    @entry = journal_entry
  end

  def extract_and_create_tags
    extract_symbol_tags
    extract_setup_tags
    extract_emotion_tags
    extract_strategy_tags
    extract_mistake_tags
  end

  private

  def extract_symbol_tags
    @entry.content.scan(/\$([A-Z0-9]{1,10})\b/).flatten.uniq.each do |symbol|
      security = Security.find_by(symbol: symbol)

      @entry.journal_tags.find_or_create_by!(
        tag_type: 'symbol',
        tag_value: symbol,
        is_auto_parsed: true,
        security_id: security&.id
      )
    end
  end

  def extract_setup_tags
    @entry.content.scan(/#([A-Za-z0-9_]+)/).flatten.uniq.each do |setup|
      @entry.journal_tags.find_or_create_by!(
        tag_type: 'setup',
        tag_value: setup,
        is_auto_parsed: true
      )
    end
  end

  def extract_emotion_tags
    @entry.content.scan(/@([A-Za-z]+)/).flatten.uniq.each do |emotion|
      # Validate against predefined emotions or create new
      @entry.journal_tags.find_or_create_by!(
        tag_type: 'emotion',
        tag_value: emotion,
        is_auto_parsed: true
      )
    end
  end

  # Similar methods for strategy and mistake tags
end
```

**Controller**:
```ruby
class JournalEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal_entry, only: [:show, :edit, :update, :destroy]

  def index
    @entries = current_user.journal_entries
                .includes(:journal_tags, :journal_media)
                .order(entry_date: :desc)

    # Apply filters
    @entries = @entries.where(entry_type: params[:type]) if params[:type].present?
    @entries = @entries.where("entry_date >= ?", params[:date_from]) if params[:date_from].present?

    # Tag filtering
    if params[:tag].present?
      @entries = @entries.joins(:journal_tags)
                          .where(journal_tags: { tag_value: params[:tag] })
    end

    # Full-text search
    if params[:q].present?
      @entries = @entries.where("search_vector @@ plainto_tsquery(?)", params[:q])
    end

    @entries = @entries.page(params[:page]).per(25)
  end

  def create
    @entry = current_user.journal_entries.build(journal_entry_params)

    if @entry.save
      redirect_to @entry, notice: "Journal entry created successfully."
    else
      render :new
    end
  end

  # ... other CRUD actions

  private

  def journal_entry_params
    params.require(:journal_entry).permit(
      :entry_type, :entry_subtype, :title, :content, :entry_date,
      :trade_id, :security_id, :is_pinned, :is_private
    )
  end
end
```

---

## Mobile Considerations

**PWA Optimizations**:
1. **Simplified Editor**: Fewer toolbar buttons, focus on typing
2. **Voice Input** (Phase 2): Dictate journal entries, auto-transcribe
3. **Photo Capture**: Take chart screenshot directly from camera
4. **Offline Drafts**: Save locally, sync when online
5. **Quick Templates**: One-tap templates for common entries

**Mobile UI Adjustments**:
- Single-column layout (no sidebars)
- Bottom navigation for filters
- Swipe gestures (swipe left to tag, swipe right to delete)
- Floating "+" button for quick new entry

---

## Phase 1 vs. Phase 2 Features

### Phase 1 (MVP - 12 weeks)
✅ Core journal entry CRUD
✅ Markdown editor with live preview
✅ Entry types: Trade Note, Daily Log, Weekly Review, Monthly Report, Learning Note
✅ Auto-parsing tags: $SYMBOL, #Setup, @Emotion
✅ Manual tagging system
✅ Image upload (drag-drop, paste)
✅ Checklists (basic markdown tasks)
✅ Search (full-text + tag filtering)
✅ Templates (5 system templates)
✅ Link to trades and securities
✅ Feed save functionality
✅ Temporal navigation (today, this week, this month)

### Phase 2 (Post-MVP - 8 weeks)
⏳ Journal analytics dashboard
⏳ Behavioral insights (emotion → performance correlation)
⏳ Image annotation tool
⏳ Custom template builder with variables
⏳ Calendar view
⏳ Checklist validation (critical items)
⏳ Version history (see edit timeline)
⏳ Embed live charts in entries `[chart:RELIANCE:1D]`
⏳ Voice input for mobile
⏳ Offline mode for PWA

### Phase 3 (Social - Future)
🔵 Public journal entries (share with community)
🔵 Mentorship (share journal with mentor)
🔵 Comments on journal entries
🔵 Community templates marketplace

---

## Success Metrics

**Engagement KPIs**:
- **Journal Coverage**: % of trades with journal entries (target: 85%+)
- **Consistency**: Average journal entries per week (target: 5+)
- **Depth**: Average word count per entry (target: 300+)
- **Tag Usage**: Average tags per entry (target: 3+)

**Feature Adoption**:
- **Templates**: % of users using templates (target: 70%+)
- **Learning Library**: Average learning notes per user (target: 5+)
- **Feed Saves**: % of users saving from feed (target: 40%+)
- **Checklists**: % of trade notes with checklists (target: 60%+)

**Quality Indicators**:
- **Search Usage**: % of users using search weekly (target: 50%+)
- **Media Uploads**: Average images per trade note (target: 2+)
- **Review Frequency**: % of users writing weekly/monthly reviews (target: 40%+)

---

## Competitive Advantages Over Existing Platforms

| Feature | TradeFlow | TraderVue | TradesViz | Edgewonk |
|---------|-----------|-----------|-----------|----------|
| **Markdown Support** | ✅ Full GFM | ❌ Plain text | ❌ Rich text | ❌ Forms only |
| **Temporal Organization** | ✅ Trade/Day/Week/Month | ⚠️ Trade + Daily only | ⚠️ Trade + Day only | ⚠️ Trade only |
| **Learning Library** | ✅ Non-temporal notes | ❌ | ❌ | ❌ |
| **Auto Tag Parsing** | ✅ $, #, @ syntax | ❌ Manual only | ⚠️ Manual tags | ⚠️ Predefined only |
| **Feed Integration** | ✅ Save from feed | ❌ | ❌ | ❌ |
| **Checklist Templates** | ✅ Interactive MD | ❌ | ⚠️ Custom only | ✅ 50+ metrics |
| **Image Annotation** | ⏳ Phase 2 | ❌ | ⚠️ Limited | ❌ |
| **Mobile PWA** | ✅ Phase 1 | ❌ Web only | ✅ Native app | ❌ Desktop-first |
| **Psychology Focus** | ⏳ Phase 2 | ❌ | ❌ | ✅ Best-in-class |
| **Price (Annual)** | ₹299/mo Pro | $588 (Gold) | Free tier | $169/year |

**Key Differentiators**:
1. **Markdown-first** = portability, power, familiarity
2. **Unified journal** = trade notes + daily logs + learning library in one place
3. **AI-assisted tagging** = less manual work, more insights
4. **Indian market focus** = ₹ formatting, NSE/BSE, local brokers

---

## Next Steps

1. ✅ Research complete (this document)
2. Create database migrations for journal tables
3. Implement JournalEntry model with markdown processing
4. Build journal index page with filters
5. Build markdown editor with live preview
6. Implement tag extraction service
7. Create 5 system templates
8. Add image upload functionality
9. Implement search with tag filtering
10. Create journal analytics dashboard (Phase 2)

**Recommended Development Order**:
- **Week 1-2**: Data model + basic CRUD
- **Week 3-4**: Markdown editor + auto-tagging
- **Week 5-6**: Templates + image upload
- **Week 7-8**: Search + temporal navigation
- **Week 9-10**: Polish + mobile optimization
- **Week 11-12**: Analytics dashboard (Phase 2)

---

## Appendix: Example Journal Entries

### Example 1: Trade Note with Full SEPA Analysis

```markdown
# Trade Entry: $RELIANCE Stage 2 Breakout

## Setup Analysis
- **Date**: 2025-01-03
- **Strategy**: #Stage2Breakout #SEPAEntry
- **Stage**: [x] 2 (confirmed)
- **RS Rank**: 8.5 / 10

## SEPA Checklist (6/6 ✓)
- [x] Stock in Stage 2 uptrend (confirmed)
- [x] Pocket pivot on volume 40%+ above average
- [x] RS line at or near new highs
- [x] 50-day MA rising
- [x] Above 200-day MA
- [x] Tight base (12% depth, < 15% requirement)

## Entry Rationale
RELIANCE broke out of a 3-week tight base with strong volume (65% above average).
The pocket pivot occurred on Jan 2 after a minor pullback to the 10-day MA.
RS line made new high alongside price, confirming relative strength vs. NIFTY.

Market condition: Bullish (@Confident about market)
Sector: Energy sector showing strength, #SectorRotation into value

## Risk Management
- **Entry Price**: ₹2,500
- **Stop Loss**: ₹2,425 (3% below base, just under 10-day MA)
- **Target**: ₹2,750 (10% gain, prior resistance from 2024)
- **Position Size**: 100 shares (₹2,50,000 invested)
- **Risk Amount**: ₹7,500 (3% of ₹2,50,000)
- **Risk % of Account**: 1.5% of ₹5,00,000 account
- **R-Multiple Target**: 3.3R (₹250 gain per share vs. ₹75 risk)

## Entry Chart
![RELIANCE entry chart showing Stage 2 breakout](reliance_entry_jan3.png)

## Emotional State
Feeling: @Confident @Patient
Confidence (1-5): 4/5
Notes: Waited for perfect setup, didn't chase. Feel disciplined and calm.

## Tags
$RELIANCE #Stage2Breakout #SEPAEntry @Confident /Momentum
```

### Example 2: Daily Journal with Multiple Trades

```markdown
# Daily Journal: January 3, 2025

## Market Overview
**Indices**: NIFTY 21,850 (+0.8%), BANKNIFTY 45,200 (+1.2%)
**Market Condition**: [x] Bull  [ ] Bear  [ ] Neutral  [ ] Choppy

Strong opening after positive global cues. FIIs bought heavily (₹2,000 Cr net).
Energy and Banking sectors led. IT lagged.

## Trades Today
1. $RELIANCE - Long entry at ₹2,500 (Stage 2 breakout) ✅
2. $INFY - Watchlist only (Stage 1 base, waiting) ⏳
3. $TATAMOTORS - Passed (no volume confirmation) ❌

## What Went Well
- Stuck to my plan: Only entered RELIANCE after full SEPA criteria met
- Avoided #FOMO on TATAMOTORS despite +3% move
- Updated my watchlist analysis for $INFY

## What Went Wrong
- Almost entered INFY too early, caught myself (!EnteredTooEarly pattern)
- Spent too much time checking prices intraday (15 times)

## Lessons Learned
> "Volume confirms the story. Without it, price alone means nothing."

Reminded myself why pocket pivots matter - RELIANCE had the volume, TATAMOTORS didn't.

## Emotional State
Overall mood: @Disciplined @Calm
Energy level (1-5): 4/5
Discipline score (1-5): 4/5 (lost 1 point for excessive price checking)

## Tomorrow's Plan
- Monitor RELIANCE for first pullback to 10-day MA (potential add)
- Continue watching $INFY for Stage 2 entry
- Review [[My SEPA Criteria]] learning note to reinforce
```

### Example 3: Learning Note (Evergreen Knowledge)

```markdown
# My SEPA Setup Criteria (v3.2)

**Category**: #TradingSetups #SEPA
**Date Created**: 2024-11-15
**Last Updated**: 2025-01-03 (added RS line criterion)

## Overview
SEPA (Specific Entry Point Analysis) is my primary swing trading setup for Stage 2 stocks.
This is an evolving checklist based on Minervini's principles adapted for Indian markets.

## Core Criteria (All Must Be Met)

### 1. Stage 2 Uptrend Confirmed
- [ ] Stock in Stage 2 (rising 50-day MA, price above 200-day MA)
- [ ] 50-day MA > 200-day MA (uptrend structure)
- [ ] Price > 50-day MA > 200-day MA (proper alignment)

**My Rule**: If 50-day MA is flat or declining, PASS (even if price above it)

### 2. Pocket Pivot
- [ ] Price closed higher than highest point of prior 10 days
- [ ] Volume on pivot day > 40% above 10-day average
- [ ] Preferably on green candle (but not required if volume extreme)

**My Adaptation**: In Indian markets, 40% volume increase is harder. I accept 30% if all other criteria are perfect.

### 3. RS Line at New Highs
- [ ] RS line (stock vs. NIFTY) at or within 5% of 52-week high
- [ ] RS line making new high alongside price (best scenario)

**Added 2025-01-03**: This criterion significantly improved my win rate from 68% to 82%.

### 4. Tight Base
- [ ] Base depth < 15% (measure high-to-low)
- [ ] Base duration: 3-8 weeks ideal (too short = volatility, too long = energy dissipation)
- [ ] Price contractions toward end of base (volatility contraction pattern)

### 5. Moving Average Alignment
- [ ] 10-day MA rising
- [ ] 50-day MA rising
- [ ] Price ideally near 10-day MA (shows normal pullback action)

### 6. Market Condition
- [ ] NIFTY in Stage 2 or strong Stage 1
- [ ] Sector showing relative strength (top 3 sectors by performance)

**My Rule**: Never enter SEPA setups if NIFTY in Stage 4 (distribution), even if individual stock looks perfect.

## Examples from My Trades

### ✅ Perfect SEPA: $RELIANCE (Jan 3, 2025)
- Stage 2: ✓ (50-day rising, above 200-day)
- Pocket Pivot: ✓ (65% volume increase)
- RS Line: ✓ (new high with price)
- Tight Base: ✓ (12% depth, 3 weeks)
- MA Alignment: ✓ (all rising)
- Market: ✓ (NIFTY +0.8%, bullish)

**Result**: +10% in 7 days, exited at target

### ❌ Failed SEPA: $TATAMOTORS (Oct 15, 2024)
- Stage 2: ✓
- Pocket Pivot: ✗ (only 18% volume, ignored my rule)
- RS Line: ✓
- Tight Base: ✓
- MA Alignment: ✓
- Market: ✓

**Result**: -2% stop loss hit next day, lack of volume = lack of conviction

**Lesson**: !IgnoredMyRules - Volume is non-negotiable

## Common Mistakes to Avoid
1. !EnteredTooEarly - Entering before pocket pivot completes
2. !IgnoredVolume - Accepting weak volume because "everything else looks good"
3. !FOMOEntry - Entering Stage 3 stocks that look like Stage 2 (@FOMO)
4. !BadMarket - Entering during NIFTY Stage 4 decline

## Related Topics
- [[Understanding Weinstein Stage Analysis]]
- [[How I Calculate RS Line]]
- [[Position Sizing for SEPA Setups]]

## Performance Stats
(As of Jan 3, 2025)
- **Total SEPA Trades**: 28
- **Win Rate**: 82% (23 wins / 28 trades)
- **Avg R-Multiple**: 2.8R
- **Best Trade**: $RELIANCE (+10%, 3.3R)
- **Worst Trade**: $TATAMOTORS (-2%, -0.67R)

## Changelog
- **v3.2 (2025-01-03)**: Added RS line criterion (improved win rate)
- **v3.1 (2024-12-10)**: Relaxed volume to 30% for perfect setups
- **v3.0 (2024-11-15)**: Initial SEPA criteria documented
```

---

**End of Specification**
