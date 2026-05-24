# Codex Project Notes — joruri-gw

## Migration Strategy

This project is being migrated toward an Ubuntu 26.04 container runtime.

Do not jump directly to Ubuntu 26.04. First create a reproducible legacy container environment, then raise Ubuntu, Ruby, and Rails one step at a time. Every step must pass the agreed verification checks before moving to the next step.

Ruby 2.3 is end-of-life and must be treated only as a temporary migration baseline. The Ubuntu 18.04 environment exists to reproduce the current application, not as a final runtime.

## Current State

| Item | Current |
|---|---|
| Rails | 4.2.7 |
| Ruby | 2.3 (from INSTALL.txt) |
| Install path | `/var/share/jorurigw` |
| Modules | 15 (gw / gwbbs / gwboard / gwcircular / gwfaq / gwmonitor / gwqa / gwsub / gwworkflow / questionnaire / enquete / doclibrary / digitallibrary / sys / system) |
| Controllers | 270 |
| Models | 328 |
| `render :text =>` | 22 箇所 |
| `find_by_*` dynamic finders | 77 箇所 (app/ + lib/) |
| jpmobile-related code | 51 箇所 |
| `.ruby-version` file | not present |
| Docker files | not present |
| Test suite | not present |

## Phase 0: Pin Current Behavior And Verification Base

Prepare Docker Compose around the current application shape.

Target services over the full phase:

- `app`: Ubuntu 18.04 + Ruby 2.3.x + Bundler 1.17.x + Rails 4.2.7
- `db`: MySQL 5.6
- optional `ldap`: OpenLDAP test container
- optional `memcached`: Memcached container

Initial Docker work should start with only the application container. Do not add database or other service containers until the Rails app container can build and boot.

Phase 0 completion criteria:

- `bundle install`
- `db:schema:load`
- `db:seed`
- `assets:precompile`
- Rails server boot
- admin login
- main GW module display (schedule / workflow / board)
- `delayed_job` execution
- `whenever` equivalent scheduled tasks

## Phase 1: Reproduce On Ubuntu 18.04 + Ruby 2.3 + Rails 4.2

Use Ruby 2.3.x for the first reproducible container.

Preferred default:

- Ruby 2.3.8 for migration stability
- Ruby 2.3.1 only when strict historical reproduction is required

Ruby 2.3 requires OpenSSL 1.0.x. Include OpenSSL 1.0.x only as a build/runtime compatibility aid for this phase. Do not carry this approach into the final runtime.

Install path inside container: `/var/share/jorurigw`

Use `doc/INSTALL.txt` as the primary reference for the legacy installation procedure and system package requirements.

## Phase 2: Stabilize Within Rails 4.2, Then Raise to Rails 5.2

Before large OS jumps, clean up application dependencies and move safely.

### 2-1: Gem cleanup (prerequisite for Rails 5+)

Remove or replace problematic gems before any Rails upgrade:

| Gem | Action |
|---|---|
| `therubyracer 0.10.2` | Remove; add `mini_racer` or install Node.js |
| `execjs 1.4.0` | Remove with therubyracer |
| `hpricot 0.8.4` | Replace with `nokogiri` (likely already a transitive dep) |
| `ri_cal 0.8.8` | Replace with `icalendar ~> 2.10` |
| `activerecord-deprecated_finders` | Remove after rewriting `find_by_*` calls (77 places) |
| `dynamic_form 1.1.4` | Remove after converting to Strong Parameters |
| `zipruby 0.3.6` | Replace with `rubyzip ~> 2.3` |
| `jpmobile 4.2.3` | Remove; delete all mobile-related code (51 places) |
| `tamtam 0.0.3` | Remove with jpmobile |
| `calendar_date_select 2.0.0` | Replace with `flatpickr` (JS migration) |
| `protected_attributes` | Remove after converting to Strong Parameters |

### 2-2: Code fixes required before Rails 5

1. **`render :text =>` → `render plain:`** (22 places)
   ```bash
   grep -rl "render :text" app/ lib/ | xargs sed -i "s/render :text =>/render plain:/g"
   ```

2. **`find_by_*` dynamic finders → `find_by()`** (77 places in app/ + lib/)
   ```ruby
   # Old
   User.find_by_login(login)
   # New
   User.find_by(login: login)
   ```
   Use a conversion script for bulk replacement.

3. **`before_filter` → `before_action`**
   ```bash
   grep -rl "before_filter" app/ | xargs sed -i 's/before_filter/before_action/g'
   ```

4. **jpmobile cleanup** (51 places)
   Remove from `ApplicationController`:
   - `include Jpmobile::ViewSelector`
   - `trans_sid`
   - `after_action :inline_css_for_mobile, :mobile_access_view`
   - `inline_css_for_mobile`, `mobile_access_view`, `tamtam_css` methods

5. **`ApplicationRecord` introduction** (required for Rails 5)
   ```ruby
   # app/models/application_record.rb
   class ApplicationRecord < ActiveRecord::Base
     self.abstract_class = true
   end
   ```
   Change all models from `< ActiveRecord::Base` to `< ApplicationRecord`.

6. **`belongs_to` optional fix** (Rails 5 makes belongs_to required by default)
   Add `optional: true` to associations that are intentionally nullable.

### 2-3: Recommended Rails upgrade order

| Step | Ubuntu | Ruby | Rails | Purpose |
|---|---:|---:|---:|---|
| A | 18.04 | 2.3.x | 4.2.7 | Reproduce current app |
| B | 18.04 / 20.04 | 2.5 / 2.6 | 5.0 → 5.2 | Stabilize Rails 5 |
| C | 20.04 | 2.7.x | 6.0 / 6.1 | Prepare before Ruby 3 |
| D | 22.04 | 3.1.x | 6.1 / 7.0 | Start OpenSSL 3 era compatibility |
| E | 24.04 | 3.2 / 3.3 | 7.1 / 7.2 | Move toward current Rails |
| F | 26.04 | 3.3 / 3.4 / 4.0 | 7.2+ / 8.x | Final runtime candidate |

Dependencies that need special attention when crossing Rails 5:

- `activerecord-session_store`: current locked version constrains Rails below 5.1; update before moving to 5.1.
- `delayed_job_active_record`: update for Rails 5.1+.
- `therubyracer` / `libv8`: replace with Node.js or `mini_racer` (must be done before Ruby 3).
- `hpricot`: deprecated; replace with Nokogiri (calendar / iCal features).
- `zipruby`: replace with `rubyzip`.
- `ri_cal`: replace with `icalendar ~> 2.10`; API is significantly different — test calendar / iCal export features.

## Phase 3: Rails 6 — Zeitwerk And Thread Safety

### 3-1: Zeitwerk autoloader (Rails 6.0 — major risk)

The current `config.autoload_paths += %W(#{config.root}/lib)` breaks under Zeitwerk because it requires strict file-name/class-name correspondence.

**Recommended approach** — exclude `lib/` from autoloading and use explicit `require`:

```ruby
# config/application.rb
Rails.autoloaders.main.ignore("#{config.root}/lib")
require_relative '../lib/joruri'
require_relative '../lib/core'
require_relative '../lib/gw'
require_relative '../lib/gwbbs'
require_relative '../lib/gwboard'
# ... all top-level lib files
```

Alternatively, restructure `lib/` to be Zeitwerk-compliant (high effort — verify directory naming against class names for all 15+ modules).

Run `rails zeitwerk:check` after any change and resolve all errors before proceeding.

### 3-2: `Core` class thread-safety fix (mandatory before Rails 6 / Puma)

`lib/core.rb` uses `cattr_*` class variables for global state (logged-in user, etc.). In Rails + Puma multi-threaded mode this causes **user data leakage between requests**.

Replace all `cattr_*` in `Core` with `Thread.current` storage:

```ruby
module CoreStorage
  KEYS = %i[title map_key env params script_uri request_uri internal_uri
            ldap imap user user_group dispatched messages now].freeze

  KEYS.each do |key|
    define_method(key)       { Thread.current[:"core_#{key}"] }
    define_method(:"#{key}=") { |v| Thread.current[:"core_#{key}"] = v }
  end
end

class Core
  extend CoreStorage
end
```

This must be completed and verified before any multi-threaded Puma configuration is used.

### 3-3: Rails 6.1

- Set `config.active_record.legacy_connection_handling = false`.
- Session DB separate connection: use Rails 6.1 multi-DB feature if keeping the separate session store.
- Review `model.errors[:field].first` → `model.errors.where(:field).first&.message` where needed.

## Phase 4: Rails 7 — Asset Pipeline And JavaScript

### 4-1: CoffeeScript → JavaScript conversion

Find all CoffeeScript files and convert them before removing `coffee-rails`:

```bash
find app/assets/javascripts -name "*.coffee" -o -name "*.js.coffee"
npx decaffeinate app/assets/javascripts/**/*.coffee
```

### 4-2: jQuery gems → npm

Remove Rails gem wrappers; manage via npm instead:

```ruby
# Remove from Gemfile:
# gem 'jquery-rails'
# gem 'jquery-ui-rails'
# gem 'jquery-timepicker-addon-rails'
# gem 'jquery-fileupload-rails'
```

```json
// package.json
{
  "dependencies": {
    "jquery": "^3.7",
    "jquery-ui": "^1.13",
    "jquery-ui-timepicker-addon": "^1.6"
  }
}
```

```javascript
// app/javascript/application.js
import jQuery from 'jquery'
window.$ = window.jQuery = jQuery
import 'jquery-ui'
```

### 4-3: `calendar_date_select` → `flatpickr`

Replace all `calendar_date_select` helper calls with `flatpickr`:

```javascript
import flatpickr from 'flatpickr'
import { Japanese } from 'flatpickr/dist/l10n/ja'
flatpickr.localize(Japanese)
```

Search for all call sites:

```bash
grep -r "calendar_date_select\|CalendarDateSelect" app/views/ app/helpers/
```

### 4-4: Sass migration

```ruby
# gem 'sass-rails'  → remove
gem 'dartsass-rails'
```

### 4-5: Import Maps vs jsbundling

Due to existing jQuery dependency across 270+ controllers, use `jsbundling-rails` + npm rather than Import Maps. Import Maps can be adopted incrementally for new pages that do not depend on jQuery.

Rails 7.2 requires Ruby 3.1 or newer. Treat Rails 7.2 as the practical first long-term milestone.

## Phase 5: Rails 8 And Final Runtime

### 5-1: Asset pipeline

Rails 8 defaults to Propshaft. Choose one:

- Keep Sprockets: add `gem 'sprockets-rails'` explicitly.
- Migrate to Propshaft: remove Sprockets-specific helpers and configuration.

### 5-2: Solid Queue (replaces delayed_job)

```ruby
gem 'solid_queue'
# Remove: gem 'delayed_job_active_record', gem 'daemons'
```

Run `delayed_job` as a separate process (not via in-container cron) until Solid Queue is stable.

### 5-3: Solid Cache / Solid Cable evaluation

Current setup uses Dalli (Memcached). Evaluate migration to Solid Cache. Keep Dalli until the evaluation is complete.

### 5-4: Session store review

Current setup uses `activerecord-session_store` with a separate DB connection. Options for Rails 8:

- Solid Cache-backed session store.
- Cookie store (if session size permits).

### 5-5: Ruby 4 (future)

Ruby 4.0 is not yet released (as of 2026). Reach and stabilize Rails 8 + Ruby 3.x first. After Ruby 4 releases, address:

- `frozen_string_literal: true` default behavior changes.
- Any deprecated APIs accumulated through Ruby 3.x series.
- Ractor compatibility (Core thread-safety fix is a prerequisite).

## Verification Gate For Every Step

Do not proceed to the next migration step until these checks pass:

- `bundle install`
- `rails runner 'puts Rails.version'`
- `db:create db:schema:load db:seed`
- `assets:precompile`
- Rails server boot
- admin login
- GW schedule display (monthly / weekly / daily views)
- GW workflow create / approve flow
- GW board post and list
- File upload and download
- `delayed_job` execution
- `whenever` scheduled task registration
- Brakeman and `bundle-audit` equivalent security checks

## Docker Development Rules

When preparing Docker-related files, use `doc/INSTALL.txt` as the primary reference for the legacy installation procedure and system package requirements.

Use `bin/docker-phase1` as the project-local command wrapper for the phase 0/1 Docker workflow:

- `bin/docker-phase1 build`: runs `docker compose build app`.
- `bin/docker-phase1 check`: runs `docker compose run --rm app ruby -v` and `docker compose run --rm app bundle exec rails runner 'puts "Rails #{Rails.version} booted"'`.
- `bin/docker-phase1 up`: runs `docker compose up app`.
- `bin/docker-phase1 all`: runs build, check, then starts the app.

Use `bin/docker-phase2` for Rails 5 upgrade work. It targets the `app-phase2` Compose service, keeps Ruby 2.3.8 for the first Rails 5.0 step, keeps separate bundle/log/tmp/assets volumes from phase 0/1, and exposes the Rails server on `http://localhost:3001/`.

- `bin/docker-phase2 build`: runs `docker compose build app-phase2`.
- `bin/docker-phase2 check`: runs Ruby version and Rails boot checks in `app-phase2`.
- `bin/docker-phase2 up`: runs `docker compose up app-phase2`.
- `bin/docker-phase2 bundle-update-rails50`: runs a conservative Rails lockfile update in `app-phase2`.

Use the `app-ruby25` Compose service, behind the `ruby-upgrade` profile, only after the Rails 5.0 patch update is stable and `therubyracer` has been removed or replaced.

The current project root directory on the host should be mounted into the container at `/var/share/jorurigw`. The source tree should remain editable from the host. Avoid writing large generated trees into the host checkout.

Gems, logs, temporary files, compiled assets, uploads, and similar generated folders should live on the container side as Docker named volumes. Do not let those paths create many files in the host-shared source tree.

Container-side generated paths must include Docker named volumes for:

- `/var/share/jorurigw/vendor/bundle`
- `/var/share/jorurigw/.bundle`
- `/var/share/jorurigw/log`
- `/var/share/jorurigw/tmp`
- `/var/share/jorurigw/public/assets`
- `/var/share/jorurigw/upload`

The application container must create and run as:

- user: `joruri`
- uid: `1000`
- gid: `1000`

Ensure `/var/share/jorurigw` and container-side writable paths are readable and writable by `joruri`. Read-only mounted configuration files may be skipped by ownership-fix logic.

For phase 0/1, database and other service containers should not be introduced until the app container can build and Rails can boot.

Do not rely on in-container cron for final operation; use a scheduler container or external job runner.
