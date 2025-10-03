## IBKR trade import plan (IBKR-sync)

This document proposes a pragmatic v1 for importing Interactive Brokers (IBKR) trades into our system, plus an automated pull alternative. It also defines a small, standard CSV format users can export to and upload, which we can reuse for other brokers.

### Scope and goals
- **Goal**: get executed trades into our domain as `Entry` → `Trade` mapped to `Account`/`Security`, with quantity, price, fees, side, timestamps, and currency.
- **Out of scope**: positions, interest, cash activity, corporate actions. These can be phased in later.

---

## Option A — Manual file import (IBKR Flex CSV → Standard CSV)

**Summary**: Users export a Trade Confirmation Flex Query from IBKR Client Portal and upload the CSV. We normalize IBKR fields into our standard CSV and import.

**User steps (IBKR)**
1) Client Portal → Performance & Reports → Flex Queries → Trade Confirmation → Create
2) Include fields: Symbol, Asset Class, Trade Date, Trade Time, Quantity, Trade Price, Buy/Sell, Currency, Commission, Fees, Net Cash, Account ID, Order ID, Execution ID
3) Format: CSV, Date `yyyyMMdd`, Time `HHmmss`
4) Run for desired date range and download CSV

**App steps**
- Upload CSV → detect broker=IBKR → parse → map → validate → stage → import to `Entry(Trade)` and related joins.

**Trade-offs**
- Pros: Very low engineering risk; works for any account type; no IBKR API keys; easy to support offline users.
- Cons: Manual; not real-time; users must remember to export and upload; CSV schema variations can break parsing.

---

## Option B — Automated pull (IBKR Flex Web Service token)

**Summary**: IBKR Flex Web Service lets us pull the exact Flex Query via HTTPS with `token` + `q={queryId}`, returning XML (or CSV). We poll on a schedule to ingest new executions.

**Prereqs**
- User creates a Flex **Trade Confirmation** query in Client Portal and generates a Flex **token** + **queryId**.
- User pastes `token` and `queryId` into our app’s IBKR connection settings.

**App steps**
- On schedule (e.g., every 15 min / hourly), call Flex Web Service for a short rolling window (e.g., last 7 days) to handle late corrections.
- Parse XML/CSV → map to our standard model → de-duplicate by `ExecutionID`/`OrderID`/`AccountID` + timestamp/qty/price hash.

**Trade-offs**
- Pros: Automated; no TWS/Gateway to run; reliable IBKR-supported pull; minimal user effort after setup.
- Cons: Not push/webhook; polling cadence limits “real-time”; token/query management UX required; XML nuances.

---

## Webhook / push capability
- IBKR does **not** provide first-party webhooks for executions.
- Near-real-time alternatives require the Client Portal Gateway or TWS/IB Gateway APIs with a long-running process. These are heavier operationally than Flex Web Service polling.

---

## Standard CSV import format (broker-agnostic v1)

This is the format we ask users (or our mappers) to produce. We can accept either: (1) user uploads broker CSV and we detect+map; or (2) user uploads the following standard CSV directly.

Required header row (case-sensitive):

```csv
broker,account_id,account_display,execution_id,order_id,symbol,asset_class,side,qty,price,currency,exec_time,trade_date,fees_total,commission,net_amount,venue,notes
```

Field definitions:
- **broker**: short code, e.g., `ibkr`
- **account_id**: broker account identifier (e.g., `U1234567`)
- **account_display**: user-friendly account name (optional)
- **execution_id**: broker execution id (unique per fill)
- **order_id**: broker order id (optional but recommended)
- **symbol**: ticker or contract symbol (e.g., `AAPL`)
- **asset_class**: `STK|OPT|FUT|FX|BOND|FUND|CRYPTO|CASH|OTHER`
- **side**: `BUY|SELL|BUY_TO_OPEN|SELL_TO_CLOSE|SELL_SHORT|BUY_TO_COVER` (map to `buy/sell` + open/close where possible)
- **qty**: signed or absolute numeric; importer will sign by `side`
- **price**: execution price per unit, in trade currency
- **currency**: ISO 4217, e.g., `USD`
- **exec_time**: ISO 8601 timestamp with timezone if possible; else combine date+time
- **trade_date**: `YYYY-MM-DD`
- **fees_total**: all non-commission fees in trade currency (can be 0)
- **commission**: commission amount in trade currency (can be 0)
- **net_amount**: optional; if blank we compute: `signed_qty * price - commission - fees_total`
- **venue**: optional execution venue/exchange
- **notes**: free text

Validation rules:
- Must include at least `broker,account_id,execution_id,symbol,side,qty,price,currency,trade_date`
- `side` must be in allowed set (case-insensitive)
- `qty > 0`; importer will compute sign by `side`
- `commission,fees_total` default to 0 if blank

Deduplication:
- Key: (`broker`,`account_id`,`execution_id`) unique; if not present, fallback to hash of (`order_id`,`symbol`,`trade_date`,`qty`,`price`).

---

## Mapping to our domain

Create one `Entry` of type `Trade` per execution fill.

Derived fields:
- `amount` on `Entry`: for investment accounts, follows our sign convention where negative is inflow to the account when selling. We compute from `side`, `qty`, `price`, and fees/commission consistent with our `Entry` rules.
- `qty` and `price` on `Trade` child
- `currency` from CSV `currency`
- `date` from `trade_date` (use `exec_time` if provided for time ordering)
- `security` resolution: match by `symbol` + `asset_class` + `currency`; if missing, create placeholder `Security` for user review
- `account` resolution: match by stored broker `account_id` (or let user pick on first import and remember mapping)
- Fees/commission: attach to `Trade` and include in net cash impact according to our accounting policy

Error handling:
- Row-level errors are quarantined with reason; continue importing remaining rows
- Provide downloadable error CSV for user fixes

---

## IBKR → Standard CSV field mapping (reference)

From IBKR Flex Trade Confirmation (CSV/XML) typical fields:
- IBKR: `AccountId` → std: `account_id`
- IBKR: `Symbol` → `symbol`
- IBKR: `AssetCategory` → `asset_class`
- IBKR: `Buy/Sell` → `side` (normalize to allowed set)
- IBKR: `Quantity` → `qty`
- IBKR: `TradePrice` → `price`
- IBKR: `TradeCurrency` → `currency`
- IBKR: `TradeDate` + `TradeTime` → `trade_date` + `exec_time`
- IBKR: `IBCommission` → `commission`
- IBKR: `OtherFees` or `NetCash - (qty*price ± commission)` → `fees_total`
- IBKR: `ExecID` → `execution_id`
- IBKR: `OrderID` → `order_id`
- IBKR: `Exchange` → `venue`

Notes:
- IBKR XML attribute names vary slightly by asset category (e.g., options/futures include more legs). For v1 we support single-leg equities/ETFs; multi-leg becomes multiple rows or is flagged for review.

---

## Security and privacy
- Flex token grants data access; encrypt at rest; redact in logs; allow easy rotation.
- Limit polling window; store ETags/Last-Modified if provided; implement exponential backoff on errors.

---

## Decision guidance
- Start with **Option A** to unblock users immediately and validate mapping.
- Add **Option B** soon after for automation without running TWS/Gateway.

---

## Future (not in v1)
- Near-real-time via Client Portal Gateway/TWS API with a managed connector process.
- Corporate actions, FX trades, and multi-leg options normalization.
- Position reconciliation against daily statements.

---

## References
- IBKR Flex Queries and Flex Web Service docs (Trade Confirmation): `https://www.interactivebrokers.com/en/software/reportguide/reportguide/flex_web_service_version_3.0.htm`
- Client Portal API (gateway-based) overview: `https://www.interactivebrokers.com/en/trading/ib-api.php`



