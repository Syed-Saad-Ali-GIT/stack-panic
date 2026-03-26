# Product Requirements Plan (PRP)
## Stack Panic — Hyper-Casual Mobile Game
**Version:** 1.0  
**Date:** March 2026  
**Status:** Draft — Ready for Execution  
**Platform:** Android (iOS Phase 2)  
**Engine:** Godot 4.x  

---

## Table of Contents

1. [Executive Summary & Vision](#1-executive-summary--vision)
2. [Product Overview](#2-product-overview)
3. [Full Feature Specifications](#3-full-feature-specifications)
4. [Technical Architecture](#4-technical-architecture)
5. [Monetization Model](#5-monetization-model)
6. [Success Metrics & KPIs](#6-success-metrics--kpis)
7. [Launch & Go-to-Market Plan](#7-launch--go-to-market-plan)
8. [Risk Register](#8-risk-register)
9. [Appendix: AI Toolchain](#9-appendix-ai-toolchain)

---

## 1. Executive Summary & Vision

### The Opportunity

The hyper-casual mobile game market generates over $3B annually, with top titles reaching millions of downloads on sub-$50k production budgets. The barrier to entry has collapsed — AI tooling now enables a solo developer to produce, publish, and monetise a polished mobile game in two weeks.

Stack Panic targets this window: a proven core mechanic (stacking blocks), a 14-day build timeline, and a monetisation architecture designed to generate revenue from day one of launch.

### Vision Statement

> Build the most satisfying tap-to-stack experience on Android — so simple anyone can play it in a waiting room, so compelling they open it again on the way home.

### Strategic Goals

- Ship a playable, monetised APK within 14 days of project start
- Achieve 1,000 installs within the first 30 days organically
- Generate positive ROAS within 60 days
- Establish a reusable Godot + AdMob pipeline for future titles

### Why Stack Panic

- **Proven mechanic:** Stacking games (e.g. Stack by Ketchapp, 500M+ downloads) have validated demand with zero IP risk when implemented originally
- **Minimal assets:** Gameplay is procedurally driven — coloured rectangles, no sprite sheets
- **Rapid monetisation:** Ad inventory fills immediately on launch; no content backlog required
- **One-handed play:** Optimised for commute, queue, and break-time sessions

---

## 2. Product Overview

### Core Gameplay Loop

```
SPAWN block (slides from left/right alternating)
    ↓
PLAYER taps → block locks in place
    ↓
ENGINE calculates overhang → trims excess
    ↓
NEXT block spawns, slightly narrower (= the trimmed width)
    ↓
BLOCK width → 0 = game over
    ↓
DEATH SCREEN → retry / watch ad to revive
    ↓
SCORE posted → loop restarts
```

**Session length target:** 30 seconds (new player) to 3 minutes (skilled player)  
**Replayability driver:** Personal best score + daily leaderboard challenge

### Target Audience

| Segment | Profile | Motivation |
|---|---|---|
| Primary | Ages 18–35, casual mobile gamers | Idle time filler, score chasing |
| Secondary | Ages 13–17, Gen Z | Skill flex, shareable scores |
| Tertiary | Ages 35–50, puzzle/casual fans | Light mental engagement |

**Geography priority:** US, UK, CA, AU (highest ad eCPM markets)

### Competitive Positioning

| Title | Weakness | Stack Panic advantage |
|---|---|---|
| Stack (Ketchapp) | Old (2015), no updates | Modern visuals, daily events, social share |
| Helix Jump | High skill floor | More accessible on session 1 |
| Tower Bloxx | Complex UI | Pure single-mechanic simplicity |

---

## 3. Full Feature Specifications

### 3.1 Core Gameplay

#### Block Movement
- Blocks traverse the full screen width horizontally
- Alternating left→right / right→left direction each turn
- **Speed formula:** `base_speed + (score * 0.08)` pixels/second — capped at `max_speed`
- Speed milestones: +10% every 10 blocks stacked

| Parameter | Value |
|---|---|
| Base speed | 180 px/s |
| Speed cap | 520 px/s |
| Starting block width | 85% of screen width |
| Minimum block width (game over) | 8px |
| Block height | 40px (fixed) |

#### Perfect Tap Bonus
- If overhang ≤ 4px: "PERFECT!" bonus fires
- Block does **not** trim — maintains full width
- Screen flash (white, 60ms), score multiplier tick (+1)
- Combo: 3 consecutive perfects = double score for next 5 blocks

#### Overhang & Trim Logic
```
overhang = abs(new_block.x - stack_top.x)
if overhang >= new_block.width:
    GAME OVER (missed completely)
elif overhang <= 4:
    PERFECT (no trim)
else:
    new_block.width = new_block.width - overhang
    trim_particle_burst(overhang_side)
```

#### Game Over Conditions
1. Block width reduced to ≤ 8px
2. Block slides off completely (tap missed or no tap)

---

### 3.2 Progression & Difficulty

#### Difficulty Stages

| Stage | Score range | Speed feel | Visual theme |
|---|---|---|---|
| Calm | 0–10 | Slow, forgiving | Cool blues |
| Steady | 11–25 | Moderate | Purples |
| Rush | 26–50 | Fast | Warm oranges |
| Panic | 51–99 | Very fast | Reds |
| Frenzy | 100+ | Extreme | Cycling rainbow |

Theme shifts are animated (background hue transition over 0.5s) — no scene change.

#### Score System
- Base: +1 per successful block placed
- Perfect: +2 (instead of +1) per perfect placement
- Combo multiplier: displayed as "×2" badge on HUD, pulses on each perfect
- High score: persisted locally via `SaveManager`, compared on death screen

---

### 3.3 Daily Challenge

- Seeded with today's UTC date (`randi_from_seed(date_int)`)
- Same sequence of block speeds and directions for all players globally
- Score submitted to Firebase leaderboard
- Reward for participating: 3 cosmetic tokens (whether or not player wins)
- Resets at 00:00 UTC daily
- Push notification at 09:00 local time: "Today's challenge is live — can you top the board?"

---

### 3.4 Shop & Cosmetics

All cosmetics are **visual only** — zero gameplay impact.

#### Themes (palette swaps)
| Theme | Unlock method | Price |
|---|---|---|
| Classic (default) | Free | — |
| Neon Night | IAP or 20 rewarded videos | $0.99 |
| Pastel Pop | IAP | $0.99 |
| Gold Rush | IAP bundle | $2.99 (3-pack) |
| Arctic | Seasonal event | Free during event |
| Lava | IAP bundle | $2.99 (3-pack) |

Each theme changes: block colours, background gradient, particle colours, UI accent colour.

#### Tokens (soft currency)
- Earned: 1 token per game, 3 tokens for daily challenge, 5 tokens per rewarded video
- Spent: unlock non-IAP themes (20–50 tokens each)
- No pay-to-earn tokens — prevents P2W perception

---

### 3.5 Social & Viral Features

#### Score Share Card
- Auto-generated image on new personal best
- Contains: score, date, "Can you beat me?" CTA, app store link
- Shared via Android native share sheet (Image + text)
- Generated procedurally in Godot using `SubViewport` → `Image`

#### Ghost Run
- On retry, a translucent ghost block shows your previous run's tap timing
- Creates psychological tension and "just one more try" pull
- Toggle in settings (on by default)

#### Leaderboard
- Firebase Realtime Database — top 100 daily scores
- Display: rank, username (device name truncated), score
- Anonymous by default; optional name entry

---

### 3.6 Notifications

| Trigger | Message | Timing |
|---|---|---|
| Daily challenge | "Today's challenge is live — beat yesterday's top score" | 09:00 local |
| Lapsed player (2 days) | "Your best is [X]. Still holding up?" | 2 days post last session |
| New personal best beat by friend | (Phase 2 — requires social graph) | — |

Permission prompt shown after 3rd session (not on first open).

---

### 3.7 Settings

- Sound effects: toggle (default on)
- Background music: toggle (default on)
- Ghost run: toggle (default on)
- Haptic feedback: toggle (default on, Android vibration API)
- Notifications: toggle (links to system settings)
- Restore purchases button
- Privacy policy link
- Version number display

---

### 3.8 Onboarding

- Session 1: animated tutorial overlay (3 taps to complete)
  - Frame 1: "Tap to drop the block" (arrow pointing to screen)
  - Frame 2: "Stack as many as you can" (shows two blocks landing)
  - Frame 3: "Go!" (full speed starts)
- No skip button on first session — tutorial is 8 seconds maximum
- No tutorial on subsequent sessions

---

## 4. Technical Architecture

### 4.1 Scene Tree

```
res://
├── scenes/
│   ├── Main.tscn              # Root — handles scene transitions
│   ├── Game.tscn              # Gameplay world + Camera2D
│   ├── UI.tscn                # HUD overlay (score, combo, perfect text)
│   ├── MainMenu.tscn          # Title, Play, Daily Challenge, Shop, Settings
│   ├── DeathScreen.tscn       # Score, retry, revive (rewarded ad), share
│   ├── Shop.tscn              # Theme grid, token count, IAP buttons
│   ├── Tutorial.tscn          # First-run overlay
│   ├── Leaderboard.tscn       # Daily challenge scores (Firebase)
│   └── Block.tscn             # Reusable block (ColorRect + CollisionShape2D)
├── scripts/
│   ├── GameManager.gd         # Autoload: game state, score, lives, difficulty
│   ├── AdManager.gd           # Autoload: AdMob interstitial + rewarded
│   ├── IAPManager.gd          # Autoload: Google Play Billing
│   ├── SaveManager.gd         # Autoload: FileAccess JSON persistence
│   ├── AudioManager.gd        # Autoload: pooled AudioStreamPlayer nodes
│   ├── NotificationManager.gd # Autoload: Android local notifications
│   ├── FirebaseManager.gd     # Autoload: leaderboard read/write
│   ├── Game.gd                # Block spawning, difficulty ramp, ghost run
│   ├── Block.gd               # Movement, collision, trim, perfect detection
│   ├── UI.gd                  # Score display, combo badge, perfect flash
│   ├── DeathScreen.gd         # Score summary, share card generation
│   └── Shop.gd                # Theme unlock, token spend, IAP trigger
├── assets/
│   ├── audio/
│   │   ├── bgm_calm.ogg
│   │   ├── bgm_panic.ogg
│   │   ├── sfx_tap.wav
│   │   ├── sfx_perfect.wav
│   │   ├── sfx_trim.wav
│   │   └── sfx_gameover.wav
│   ├── fonts/
│   │   └── Nunito-Bold.ttf
│   └── themes/
│       └── default.tres
└── addons/
    ├── admob/
    └── google_play_billing/
```

---

### 4.2 Autoload Architecture

All singleton managers are registered in `project.godot` as Autoloads, accessible globally.

#### GameManager.gd
```gdscript
# Signals
signal game_started
signal game_over(score: int)
signal score_changed(new_score: int)
signal perfect_streak_changed(streak: int)

# State
var score: int = 0
var high_score: int = 0
var current_theme: String = "classic"
var lives_remaining: int = 1     # 0 = no revive available
var is_ad_free: bool = false
var daily_challenge_score: int = 0
```

#### SaveManager.gd
```gdscript
# Persisted keys (JSON file, path: user://save.json)
# high_score: int
# owned_themes: Array[String]
# token_balance: int
# total_games_played: int
# is_ad_free: bool
# last_daily_date: String       # "2026-03-26"
# daily_streak: int
```

#### AdManager.gd
```gdscript
# Signals
signal interstitial_closed
signal rewarded_earned                # user completed the rewarded video
signal rewarded_skipped               # user exited early — no reward

# Ad unit IDs (replace with real IDs before release)
const INTERSTITIAL_ID = "ca-app-pub-XXXXXXXX/XXXXXXXX"
const REWARDED_ID     = "ca-app-pub-XXXXXXXX/XXXXXXXX"

# Rules enforced here (not in game logic):
# - Interstitial: never show if is_ad_free, cap at 5/day, 3-death cooldown
# - Rewarded: always available regardless of ad_free status
```

---

### 4.3 Data Flow

```
[Player tap]
     │
     ▼
Block.gd: calculate_landing()
     │ emits: block_landed(overhang_px)
     ▼
Game.gd: handle_landing()
     │ → trim block
     │ → check game over
     │ → update score
     │ emits: GameManager.score_changed(score)
     ▼
UI.gd: update_display()
     │ → animate score label
     │ → show/hide PERFECT badge
     ▼
[Game over]
     │
     ▼
GameManager.game_over.emit(score)
     │
     ├─ SaveManager.check_high_score(score)
     ├─ AdManager.record_death() → show interstitial if conditions met
     └─ Main.gd: transition to DeathScreen
```

---

### 4.4 Persistence Model

Save file at `user://save.json` — encrypted with `FileAccess.ModeFlags.WRITE` and a static XOR key. Not secure against determined hackers; sufficient to prevent casual leaderboard cheating.

```json
{
  "high_score": 0,
  "token_balance": 0,
  "owned_themes": ["classic"],
  "is_ad_free": false,
  "total_games_played": 0,
  "daily_streak": 0,
  "last_daily_date": "",
  "daily_challenge_scores": {}
}
```

---

### 4.5 Third-Party Plugins

| Plugin | Purpose | Source |
|---|---|---|
| `godot-admob-android` | Interstitial + rewarded video ads | GitHub: Poing Studio |
| `godot-google-play-billing` | IAP (no-ads, theme bundles) | GitHub: PrecisionRender |
| Firebase Android SDK | Crash reporting, analytics, leaderboard | Google |
| `godot-local-notification` | Scheduled push notifications | GitHub: Lights & Shadows |

All plugins are GDExtension-based (Godot 4 compatible). Confirm compatibility with Godot 4.x before installing.

---

### 4.6 Performance Requirements

| Metric | Target | Minimum acceptable |
|---|---|---|
| Frame rate | 60 fps (all devices) | 45 fps on low-end |
| Cold start time | < 2.5 seconds | < 4 seconds |
| APK size | < 30 MB | < 50 MB |
| RAM usage | < 150 MB | < 250 MB |
| Battery drain | Minimal (no physics engine, 2D only) | — |

**Target devices:** Android 8.0+ (API 26+), 2GB RAM minimum

---

### 4.7 Build & Export

```bash
# Export signed APK for Play Store
godot --headless --export-release "Android" ./build/stack-panic.apk

# Required export settings
# - minSdkVersion: 26 (Android 8.0)
# - targetSdkVersion: 34 (Android 14)
# - Signed with upload keystore (keep keystore in password manager)
# - Internet permission: required (ads, leaderboard)
# - Vibrate permission: required (haptics)
```

---

## 5. Monetization Model

### 5.1 Revenue Architecture

Stack Panic uses a **hybrid model** — ad-first with IAP upsell. Ads generate the majority of early revenue; IAP scales with engaged users.

```
Revenue = (Ad Impressions × eCPM) + (IAP Units × Price)
```

### 5.2 Ad Placements

#### Interstitial Ads
- **Trigger:** Every 3 deaths (death counter resets on app restart)
- **Suppressed if:** `is_ad_free = true`, or fewer than 3 deaths this session, or fewer than 60 seconds since last interstitial
- **Placement:** Death screen transition (not during active gameplay — ever)
- **Expected eCPM:** $5–$15 (US/UK/AU traffic)
- **Cap:** Maximum 5 interstitials per user per day

#### Rewarded Video Ads
- **Trigger:** Player-initiated only, from the death screen ("Watch to revive")
- **Reward:** One full revive (block width restored to 40% of original)
- **Available to:** All users including ad-free purchasers (reward is valuable)
- **Expected eCPM:** $15–$40
- **Cap:** 1 revive per run (cannot stack revives)
- **Secondary placement:** Shop — "Watch 5 videos to unlock Neon Night theme"

#### Banner Ads
- **Not used.** Banner ads generate ~$0.30 eCPM and damage visual experience. Excluded from v1.

---

### 5.3 In-App Purchases

| SKU | Label | Price | What it does |
|---|---|---|---|
| `remove_ads` | Remove Ads | $0.99 | Stops all interstitials permanently. Rewarded video still available. |
| `theme_starter_pack` | Starter Theme Pack | $2.99 | Unlocks Neon Night + Pastel Pop (saves $0.99 vs buying separately) |
| `theme_premium_pack` | Premium Theme Pack | $2.99 | Unlocks Gold Rush + Lava |
| `token_boost` | 200 Tokens | $1.99 | Soft currency boost — skip video grinding for theme unlocks |

#### Pricing rationale
- $0.99 remove-ads: low barrier, converts ~2–3% of engaged users
- $2.99 bundles: anchoring — makes $0.99 look like the "safe" entry buy
- No single IAP above $4.99: hyper-casual audience is price-sensitive

#### IAP Rules
- All purchases are **consumable** except `remove_ads` (non-consumable, restorable)
- Restore purchases button in Settings (required by Play Store policy)
- No IAP prompt on sessions 1 or 2 — establish habit before monetising
- First IAP prompt shown on death screen after 10th game

---

### 5.4 Revenue Projections

Assumptions: 1,000 DAU, US-majority traffic, standard hyper-casual benchmarks.

| Revenue source | Monthly est. | % of total |
|---|---|---|
| Interstitial ads | $180 | 43% |
| Rewarded video ads | $140 | 33% |
| Remove Ads IAP | $60 | 14% |
| Theme bundles | $40 | 10% |
| **Total** | **~$420/mo** | 100% |

At 10,000 DAU: ~$4,200/mo. At 50,000 DAU: ~$18,000/mo (with ad yield improvements from scale).

---

### 5.5 Monetisation Rules (Non-Negotiable)

1. **Never interrupt active gameplay with an ad.** Interstitials only on death screen or main menu transition.
2. **Never block progress.** No "watch ad to continue the tutorial" or "pay to unlock next level" mechanics.
3. **Rewarded ads must always be user-initiated.** No auto-playing rewarded videos.
4. **Remove Ads must actually remove ads.** Hiding the IAP behind continued ad exposure after purchase is a Play Store violation.
5. **No dark patterns.** No fake countdown timers, no misleading "×" buttons on ads (handled by AdMob SDK).

---

## 6. Success Metrics & KPIs

### 6.1 North Star Metric

**Weekly Active Users (WAU)** — the single number that best reflects product health. Revenue and retention both feed into it.

### 6.2 Acquisition Metrics

| KPI | Target (Day 30) | Action if missed |
|---|---|---|
| Total installs | 1,000 | Increase organic content output |
| Organic install rate | > 60% | Improve ASO keywords + screenshots |
| Cost per install (paid) | < $0.30 | Pause paid, fix creative |
| Play Store rating | ≥ 4.2 stars | Address top review complaints in patch |
| Store listing CVR | > 25% | A/B test screenshots and icon |

### 6.3 Retention Metrics

| KPI | Target | Industry avg (hyper-casual) | Action if missed |
|---|---|---|---|
| Day-1 retention | ≥ 40% | 35% | Fix onboarding or core feel |
| Day-7 retention | ≥ 18% | 12–15% | Add daily challenge, improve difficulty curve |
| Day-30 retention | ≥ 8% | 5–6% | Add seasonal events, ghost run, leaderboard |
| Avg session length | ≥ 3 min | 2–2.5 min | Tune difficulty ramp |
| Sessions per DAU per day | ≥ 3 | 2.5 | Add push notifications |

### 6.4 Monetisation Metrics

| KPI | Target | Notes |
|---|---|---|
| ARPU (all users) | ≥ $0.05 | Revenue ÷ DAU ÷ days |
| ARPDAU (paying users) | ≥ $1.50 | Benchmark for upsell potential |
| IAP conversion rate | ≥ 2% | % of users who make any purchase |
| Rewarded video watch rate | ≥ 30% | % of death screens where rewarded is watched |
| Ad impressions per DAU | ≥ 4 | Reflects session depth |
| Remove Ads attach rate | ≥ 1.5% | % of total users |
| Day-7 ROAS (paid UA) | ≥ 80% | Minimum before scaling spend |
| Day-30 ROAS | ≥ 120% | Target before declaring paid UA profitable |

### 6.5 Technical Metrics

| KPI | Target |
|---|---|
| Crash-free session rate | ≥ 99.5% |
| ANR rate | < 0.5% |
| Cold start p95 latency | < 3 seconds |
| Ad fill rate | > 90% |

### 6.6 Tracking Implementation

All events sent to Firebase Analytics. Key events:

```
session_start           { theme, platform, version }
tutorial_complete       { seconds_taken }
game_start              { game_number, theme }
block_placed            { score, is_perfect, speed }
game_over               { score, is_new_high_score, death_cause }
ad_shown                { ad_type: "interstitial"|"rewarded" }
ad_rewarded_earned      { score_at_time }
iap_initiated           { sku }
iap_completed           { sku, price }
theme_unlocked          { theme_name, unlock_method: "iap"|"tokens"|"event" }
daily_challenge_played  { score, rank }
share_card_created      { score }
```

---

## 7. Launch & Go-to-Market Plan

### 7.1 Pre-Launch Checklist (Day 12–13)

#### Store Assets
- [ ] App icon: 512×512px PNG, no alpha, high contrast, readable at 48px
- [ ] Feature graphic: 1024×500px — gameplay screenshot + "Stack Panic" wordmark
- [ ] 8 screenshots (1080×1920px portrait):
  - 1–2: Core mechanic (block stacking in action)
  - 3–4: "PERFECT!" moment captured
  - 5–6: Panic mode (red theme, high score)
  - 7: Daily challenge leaderboard
  - 8: Theme shop (shows variety)
- [ ] 30-second preview video: real gameplay, no UI overlays, first 3 seconds show a perfect stack

#### Store Listing Copy

**Title (30 chars max):**
> Stack Panic – Block Tower

**Short description (80 chars max):**
> How high can you stack? One tap. Endless blocks. Zero chill.

**Long description (4000 chars):**
```
Stack the blocks. Don't miss. Simple? Not for long.

Stack Panic is the ultimate test of timing. Tap to drop a falling 
block onto your growing tower. Land it perfectly and it locks in 
full width. Miss by a fraction and the edge gets cut off — making 
the next block even harder to land.

How high can you go before it all comes crashing down?

FEATURES
• One-tap gameplay — pick up in seconds, master over weeks
• Daily challenge — same run for all players, compete globally  
• Ghost run — race your own shadow on every retry
• Combo system — land 3 perfects in a row for double score
• 6 visual themes — from cool blues to volcanic red
• Score share — auto-generate a card to challenge your friends

Stack Panic is free to play. Ads can be removed with a one-time 
purchase. No lives system. No pay-to-win. Just your tap and 
the relentless blocks.

How. High. Can. You. Go?
```

#### ASO Keywords
Primary: `stack game`, `block stacking`, `tap game`, `casual arcade`, `one tap game`  
Secondary: `hyper casual`, `reflex game`, `tower game`, `block drop`, `endless arcade`

---

### 7.2 Launch Day Playbook

**08:00** — Submit to Google Play production track  
**09:00** — Post to r/androidgaming: "I built this hyper-casual stacking game in 2 weeks as a solo dev — feedback welcome" (include 15-second GIF)  
**10:00** — Post to r/indiegaming with dev story angle  
**11:00** — TikTok: "I coded a mobile game in 14 days — here's what happened" (dev timelapse + gameplay reveal)  
**12:00** — YouTube Shorts: 30-second "Can you beat my score?" gameplay clip  
**14:00** — Share in indie dev Discord communities (Godot Discord, r/gamedev Discord)  
**16:00** — Twitter/X: gameplay GIF with #indiedev #godot #mobilegame  
**All day** — Respond to every comment within 2 hours (algorithmic boost + community goodwill)

---

### 7.3 Organic Content Strategy (Weeks 1–4)

**Content calendar — 3 posts per week minimum:**

| Content type | Platform | Angle |
|---|---|---|
| Dev diary | TikTok, YouTube Shorts | "What I learned building a game in 2 weeks" |
| Gameplay challenge | TikTok, Instagram Reels | "Can anyone beat [X] score?" |
| Behind the scenes | Twitter/X | Godot code snippets, design decisions |
| Community highlight | All | Share players' posted scores |
| Patch notes | Reddit, Twitter | "I fixed the #1 complaint" (shows responsiveness) |

---

### 7.4 Community Seeding

Before launch, recruit 20 beta testers:
- Personal network (friends, family)
- Godot Discord (#projects channel)
- r/betatesting subreddit

Beta goals:
- Validate Day-1 retention ≥ 35% with real users
- Identify top 3 friction points before public launch
- Generate first 5 Play Store reviews on launch day

Ask testers specifically for: "An honest review — even 3 stars with feedback helps more than a fake 5."

---

### 7.5 Press & Influencer Outreach

**Mobile game review sites** (email with press kit):
- Droid Gamers, TouchArcade (free games section), 148Apps, Pocket Gamer

**Micro-influencers** (10k–100k followers, mobile gaming niche):
- Offer: exclusive 48-hour early access + custom score challenge
- Do not pay for coverage in v1 — authentic organic reviews convert better

**Press kit contents:**
- 5-sentence description
- 3 gameplay GIFs (perfect tap, high score moment, game over)
- APK download link
- Contact email

---

### 7.6 Paid User Acquisition (Day 30+)

**Only begin paid UA when:**
- Day-7 retention ≥ 18%
- ARPU ≥ $0.05
- Play Store rating ≥ 4.2

**Platform:** Meta Advantage+ campaigns (proven lowest CPI for hyper-casual)

**Budget:** Start at $5/day, scale to $50/day only after 3× ROAS confirmed over 7 days

**Creative:** 15-second gameplay video, no voiceover, satisfying perfect-stack sound in first 3 seconds

**Target CPI:** < $0.30

**Audiences to test:**
1. Broad (18–45, mobile gamers, let Meta optimise)
2. Lookalike of Play Store page visitors
3. Interest: casual games, puzzle games, Ketchapp

---

### 7.7 Post-Launch Roadmap

| Week | Update | Goal |
|---|---|---|
| Week 3 | Patch: fix top 3 Play Store complaints | Improve rating from ~3.8 to 4.2+ |
| Week 4 | Add seasonal theme (e.g. "Spring Bloom") | FOMO-driven re-engagement |
| Week 6 | Daily challenge leaderboard improvements | Increase D7+ retention |
| Week 8 | iOS port (Phase 2) | Double addressable market |
| Month 3 | New mechanic variant ("Split mode") | Reactivate lapsed users |

---

## 8. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| AdMob plugin incompatible with Godot 4.x version | Medium | High | Test plugin on Day 1; have fallback (Unity Ads SDK via Android module) |
| Play Store policy rejection | Low | High | Review policy checklist before submission; avoid "stack" trademark conflicts |
| Day-1 retention < 25% | Medium | High | Pre-define pivot: add tutorial improvements + easier difficulty before scaling |
| Ad eCPM below $3 (non-US traffic heavy) | Medium | Medium | Add geo-targeting to paid UA; prioritise US/UK/CA installs |
| Godot Android export bug | Low | High | Test export on real device Day 1, not Day 13 |
| Core mechanic feels boring after 10 plays | Medium | High | Add combo system + ghost run in Week 1 (not Week 2) |
| Competitor clones the game | High | Low | Speed is the moat — be first, build reputation, ship updates faster |

---

## 9. Appendix: AI Toolchain

### Code Generation
| Tool | Use case | Cost |
|---|---|---|
| Claude (this document's author) | GDScript generation, architecture review, bug fixing | Free/Pro |
| Cursor IDE | In-editor AI autocomplete and refactoring | $20/mo |
| GitHub Copilot | Boilerplate completion | $10/mo |

### Art & Visual Assets
| Tool | Use case | Cost |
|---|---|---|
| Midjourney | Store screenshots, background concepts, icon art | $10/mo |
| DALL-E 3 (ChatGPT) | UI badges, icons, quick iterations | Free/Plus |
| Canva AI | Feature graphic, social posts, store banner | Free |
| Kenney.nl | CC0 placeholder assets during development | Free |

### Audio
| Tool | Use case | Cost |
|---|---|---|
| Suno AI | Background music (calm + panic variants) | $8/mo |
| ElevenLabs | Sound effects via text prompt | Free tier |
| Freesound.org | CC-licensed SFX library backup | Free |

### Analytics & Backend
| Tool | Use case | Cost |
|---|---|---|
| Firebase (Google) | Analytics, crash reporting, leaderboard | Free (Spark plan) |
| Google Play Console | Store management, A/B tests, review replies | $25 one-time |

### Marketing
| Tool | Use case | Cost |
|---|---|---|
| ChatGPT | Store description, keyword research, social copy | Free/Plus |
| CapCut / DaVinci Resolve | Gameplay video editing | Free |

**Total estimated AI tooling cost:** ~$50–70/month

---

*Stack Panic PRP v1.0 — Prepared for solo developer execution. All timelines assume full-time commitment (8h/day) during the 14-day build window. Adjust milestones proportionally for part-time development.*
