# Ruby 4 / Rails 8 移行計画 — joruri-gw

## 現状サマリー

| 項目 | 現状 |
|---|---|
| Rails | 4.2.10 |
| Ruby | 不明（gem バージョン推測で 2.x） |
| Joruri | 3.2.6 |
| モジュール数 | 15（gw/gwbbs/gwboard/gwworkflow 等） |
| コントローラ数 | 200+ |
| 廃止 API 使用箇所 | 1,000+ 箇所 |

---

## 主要な問題点

### A. 廃止・動作不可のGem

| Gem | 問題 | 代替 |
|---|---|---|
| `therubyracer 0.10.2` | Ruby 3+ でコンパイル不可 | `mini_racer` または Node.js |
| `hpricot 0.8.4` | 廃止済み（メンテナンス停止） | `nokogiri` |
| `ri_cal 0.8.8` | 廃止済み | `icalendar`（新版） |
| `activerecord-deprecated_finders 1.0.4` | Rails 5 以降不要 | Rails 標準クエリに書き換え |
| `dynamic_form 1.1.4` | Rails 5 以降削除 | Strong Parameters |
| `zipruby 0.3.6` | Ruby 3+ でコンパイル不可 | `rubyzip` |
| `jpmobile 4.2.3` | Rails 7+ 非対応・携帯電話機能自体が不要 | 削除 |
| `tamtam 0.0.3` | jpmobile 依存・廃止 | 削除 |
| `calendar_date_select 2.0.0` | Rails 5+ 非対応 | flatpickr 等に移行 |
| `execjs 1.4.0` | therubyracer 削除に伴い不要 | 削除 or `mini_racer` |
| `coffee-rails ~> 4.0.0` | 非推奨・CoffeeScript 不要 | 削除（JS 変換） |
| `sass-rails ~> 4.0.2` | Rails 8 では非推奨 | `dartsass-rails` |

### B. 廃止 API の使用（コード修正必要）

| パターン | 件数 | 修正方法 |
|---|---|---|
| `render :text =>` | 19 箇所 | `render plain:` へ |
| `find_by_*` 動的ファインダー | 1,082 箇所 | `find_by(xxx: val)` へ |
| `before_filter` | 複数 | `before_action` へ |
| `render :file =>` (エラーページ) | 複数 | `render file:` へ |
| `.scoped` | 複数 | `.all` or `where({})` へ |
| `trans_sid` (jpmobile) | 1 箇所 | 削除 |

### C. アーキテクチャの問題

**`Core` クラスのスレッドセーフ問題（最重要）**

`lib/core.rb` は `cattr_*` クラス変数でグローバル状態（ログインユーザー等）を管理しているが、
Rails 8 + Puma のマルチスレッド環境では別リクエストの情報が混入し、ユーザー情報漏洩・
動作不正につながる重大なリスクがある。

```ruby
# 現状（スレッドセーフでない）
cattr_accessor :user
cattr_accessor :user_group

# 変更後（スレッドローカルストレージ）
def self.user
  Thread.current[:core_user]
end
def self.user=(val)
  Thread.current[:core_user] = val
end
```

---

## 移行フェーズ計画

### フェーズ 0: 準備（1〜2週間）

目標：移行作業を安全に進めるための基盤整備

1. **現行環境のスナップショット取得**
   - `bundle exec rake routes` の出力保存
   - DB スキーマのバックアップ
   - 主要画面のスクリーンショット・動作記録

2. **テスト環境整備**
   - 開発用 Docker 環境の用意（段階的な Ruby/Rails バージョン切り替えのため）
   - RSpec または minitest の導入（現状テストが存在しない）
   - 主要機能のスモークテスト作成（スケジュール・ワークフロー・掲示板）

3. **Brakeman による脆弱性スキャン**（Gemfile に既に含まれている）

4. **`.ruby-version` ファイルの作成**（現在存在しない）

---

### フェーズ 1: Ruby 2.x → Ruby 3.2（3〜4週間）

> Rails 4.2 は Ruby 3 非対応のため、フェーズ 3（Rails 5 対応）と並行作業になる

**Ruby 3.0 の破壊的変更への対応:**

1. **キーワード引数の分離**（Ruby 2.7 で警告、3.0 でエラー）
   ```ruby
   # 旧: options ハッシュとキーワード引数の混在
   def foo(opts = {}); end
   foo(key: val)
   # 新: 明示的に分離する
   ```
   `grep -r "def \w\+(" app/ lib/` で影響箇所を洗い出す

2. **`frozen_string_literal` 対応**
   - `String#freeze` の不要な呼び出し整理
   - ミュータブルな文字列操作箇所の確認

3. **正規表現のグローバル変数**（`$~` 等）の確認

4. **.ruby-version の設定**
   ```
   3.2.x
   ```

---

### フェーズ 2: 廃止 Gem の入替え（2〜3週間）

**優先度: 高（Rails アップグレードをブロックするもの）**

```ruby
# Gemfile 変更案

# gem 'therubyracer', '0.10.2'  → 削除
# gem 'execjs', '1.4.0'         → 削除（または mini_racer に）
gem 'mini_racer'                 # Node.js が不要な場合

# gem 'hpricot', '0.8.4'        → nokogiri に書き換え後、削除
gem 'nokogiri'                   # 依存 gem に既に含まれている可能性あり

# gem 'zipruby', '0.3.6'        → rubyzip に書き換え
gem 'rubyzip', '~> 2.3'

# gem 'activerecord-deprecated_finders'  → 削除（コードを書き換えてから）
# gem 'dynamic_form'                     → 削除
```

**優先度: 中（機能削除に伴うもの）**

```ruby
# 携帯電話対応の完全削除
# gem 'jpmobile'  → 削除
# gem 'tamtam'    → 削除

# ApplicationController から以下を削除:
#   include Jpmobile::ViewSelector
#   trans_sid
#   after_action :inline_css_for_mobile, :mobile_access_view
#   inline_css_for_mobile メソッド全体
#   mobile_access_view メソッド全体
#   tamtam_css メソッド全体
```

**優先度: 低（バージョンアップのみ）**

```ruby
gem 'mysql2', '~> 0.5'
gem 'will_paginate', '~> 3.3'
gem 'net-ssh', '~> 7.0'
gem 'dalli', '~> 3.2'
gem 'whenever', '~> 1.0'
gem 'delayed_job_active_record', '~> 4.1'
gem 'icalendar', '~> 2.10'      # ri_cal の代替としても使う
gem 'prawn', '~> 2.5'
gem 'prawn-table', '~> 0.2'
gem 'memoist'                    # 最新版
gem 'capistrano', '~> 3.18'
gem 'acts_as_tree', '~> 2.9'
gem 'validates_email_format_of', '~> 1.7'
```

---

### フェーズ 3: Rails 4.2 → Rails 5.2（3〜4週間）

Rails のアップグレードは**1メジャーバージョンずつ**実施する。

#### 3-1: Rails 4.2 → 5.0

**必須対応:**

1. **`ApplicationRecord` の導入**
   ```ruby
   # app/models/application_record.rb を新規作成
   class ApplicationRecord < ActiveRecord::Base
     self.abstract_class = true
   end
   # 全モデルの `< ActiveRecord::Base` を `< ApplicationRecord` に変更
   ```

2. **`before_filter` → `before_action` 一括置換**
   ```bash
   grep -rl "before_filter" app/ | xargs sed -i 's/before_filter/before_action/g'
   ```

3. **`render :text =>` → `render plain:`**（19 箇所）
   ```ruby
   render :text => "foo"  →  render plain: "foo"
   render :nothing => true  →  head :ok
   ```

4. **`belongs_to` のオプション変更**（Rails 5 でデフォルト required）
   ```ruby
   # 既存の任意 belongs_to に optional: true を追加
   belongs_to :user, optional: true
   ```

5. **動的ファインダーの書き換え**（1,082 箇所 — 半自動化推奨）
   ```ruby
   # 旧
   User.find_by_email(email)
   User.find_by_code_and_state(code, state)
   # 新
   User.find_by(email: email)
   User.find_by(code: code, state: state)
   ```
   変換スクリプト例:
   ```ruby
   # script: convert_dynamic_finders.rb
   # find_by_x(val) → find_by(x: val) を正規表現で一括変換
   ```

6. **Strong Parameters の確認**
   - `attr_accessible` / `attr_protected` が残っていれば削除
   - コントローラの params.require / params.permit を確認

7. **`config/initializers/new_framework_defaults_5_0.rb` を有効化**

#### 3-2: Rails 5.0 → 5.2

- `config/credentials.yml.enc` の導入（`config/secrets.yml` から移行）
- Active Storage の評価（既存ファイルアップロードとの競合確認）
- `config/initializers/new_framework_defaults_5_2.rb` を有効化

---

### フェーズ 4: Rails 5.2 → Rails 6.1（3〜4週間）

#### 4-1: Rails 6.0 — Zeitwerk Autoloader 移行（最大の難関）

現状の `config.autoload_paths += %W(#{config.root}/lib)` は Zeitwerk では
**ファイル名とクラス名の厳密な対応**が要求されるため大規模整理が必要。

**問題になりやすいパターン:**
```
lib/core.rb          → Core クラス OK
lib/gw.rb            → Gw モジュール OK
lib/gwboard.rb       → Gwboard モジュール OK
lib/gwboard/model/doc/wiki.rb  → Gwboard::Model::Doc::Wiki が期待される
                                  ← 現状の命名と一致しているか要確認
```

**推奨対応方針:**
```ruby
# config/application.rb
# lib/ 配下を autoload 対象外にして明示的 require に変換
Rails.autoloaders.main.ignore("#{config.root}/lib")
# 個別に require する
require_relative '../lib/core'
require_relative '../lib/gw'
# ...
```

または、`lib/` 配下のディレクトリ構造を Zeitwerk 準拠に整理する（工数大）。

#### 4-2: `Core` クラスのスレッドセーフ対応（必須）

```ruby
# lib/core.rb の cattr_* を全て Thread.current に移行
# 対象: :user, :user_group, :dispatched, :ldap, :imap, :messages 等

module CoreStorage
  KEYS = %i[title map_key env params script_uri request_uri internal_uri
            ldap imap user user_group dispatched messages now].freeze

  KEYS.each do |key|
    define_method(key) { Thread.current[:"core_#{key}"] }
    define_method(:"#{key}=") { |v| Thread.current[:"core_#{key}"] = v }
  end
end

class Core
  extend CoreStorage
  # ...
end
```

#### 4-3: Rails 6.1

- `config.active_record.legacy_connection_handling = false`
- エラーオブジェクトの変更確認
  ```ruby
  # 旧
  model.errors[:field].first
  # 新（推奨）
  model.errors.where(:field).first&.message
  ```
- セッション DB の別接続設定を Rails 6.1 の多重 DB 機能で整理

---

### フェーズ 5: Rails 6.1 → Rails 7.1（3〜4週間）

#### 5-1: アセットパイプラインの移行

**現状**: Sprockets 3 + CoffeeScript + sass-rails 4

**変更内容:**

```ruby
# Gemfile
gem 'dartsass-rails'           # sass-rails の代替
# gem 'sass-rails'             → 削除
# gem 'coffee-rails'           → 削除（JS 変換後）
# gem 'uglifier'               → 削除
gem 'jsbundling-rails'         # npm バンドラー使用の場合
```

**CoffeeScript ファイルの変換:**
- `.js.coffee` ファイルを全て `.js` に変換
- `decaffeinate` ツール（npm）使用推奨:
  ```bash
  npx decaffeinate app/assets/javascripts/**/*.coffee
  ```

#### 5-2: jQuery の npm 移行

```ruby
# gem 'jquery-rails'                     → 削除
# gem 'jquery-ui-rails'                  → 削除
# gem 'jquery-timepicker-addon-rails'    → 削除
# gem 'jquery-fileupload-rails'          → 削除
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

`app/javascript/application.js` で import:
```javascript
import jQuery from 'jquery'
window.$ = window.jQuery = jQuery
import 'jquery-ui'
```

#### 5-3: calendar_date_select の置き換え

`flatpickr` への移行を推奨:
```javascript
import flatpickr from 'flatpickr'
import { Japanese } from 'flatpickr/dist/l10n/ja'
flatpickr.localize(Japanese)
```

既存の `calendar_date_select` ヘルパー呼び出し箇所を全置換する（工数大）。

#### 5-4: Import Maps vs jsbundling の選択

既存の jQuery 依存が多いため `jsbundling-rails` + npm が現実的。
Import Maps は jQuery を使わない新規ページ向けに段階的に採用可。

---

### フェーズ 6: Rails 7.1 → Rails 8.0（2〜3週間）

**Rails 8 の主要変更への対応:**

1. **Propshaft の評価**
   - デフォルトは Propshaft だが Sprockets も継続使用可
   - `gem 'propshaft'` に移行するか、`gem 'sprockets-rails'` を明示的に追加するか選択

2. **Solid Queue への移行評価**（`delayed_job` の代替）
   ```ruby
   # config/queue.yml を作成
   gem 'solid_queue'
   # gem 'delayed_job_active_record'  → 削除
   # gem 'daemons'                    → 削除
   ```

3. **Solid Cache / Solid Cable の評価**
   - 現状 Dalli (Memcached) を使用 → Solid Cache への移行検討

4. **セッションストアの見直し**
   ```ruby
   # 現状: activerecord-session_store + 別 DB 接続
   # → Solid Cache ベースのセッションストアか cookie store へ移行検討
   ```

5. **Deprecation warnings をすべてクリア**
   ```ruby
   # config/environments/development.rb
   config.active_support.deprecation = :raise  # 移行中は :raise を推奨
   ```

---

### フェーズ 7: Ruby 3.x → Ruby 4（将来対応）

> **注意**: 2025年8月時点で Ruby 4.0 は未リリース。Ruby 3.4 が最新安定版。
> 本フェーズは Rails 8 + Ruby 3.x で安定稼働してから着手する。

Ruby 4 リリース後に確認が必要な変更点（予測）：
- Ractors の本格的な利用（Core クラスのスレッドセーフ対応が前提）
- 削除予定の古い構文への対応
- `frozen_string_literal: true` のデフォルト化への対応
- それまでに deprecated になった API のクリア

---

## 作業量見積もり

| フェーズ | 推定工数 | 主な難所 |
|---|---|---|
| 0: 準備 | 1〜2週 | — |
| 1: Ruby 3 対応 | 3〜4週 | キーワード引数変更の影響範囲 |
| 2: Gem 入替え | 2〜3週 | hpricot → nokogiri の書き換え |
| 3: Rails 5 | 3〜4週 | 動的ファインダー 1,000+ 件 |
| 4: Rails 6 | 3〜4週 | **Zeitwerk + Core クラスのスレッドセーフ対応** |
| 5: Rails 7 | 3〜4週 | アセットパイプライン・CoffeeScript 変換 |
| 6: Rails 8 | 2〜3週 | Solid Queue 移行評価 |
| 7: Ruby 4 | 未定 | Ruby 4 リリース後 |
| **合計** | **約 5〜6ヶ月** | |

---

## リスクと注意事項

### リスク 1: `Core` クラスのスレッドセーフ問題（最重要）

Rails 8 + Puma のマルチスレッド環境で `cattr_*` のグローバル状態が別リクエストに
混入し、**ユーザー情報の漏洩や誤動作**につながる可能性がある。
フェーズ 4 で必ず対応すること。

### リスク 2: jpmobile 削除の影響範囲

`trans_sid`、`request.mobile?`、`request.smart_phone?` の呼び出しが多数存在する。
削除後、これらを呼んでいる全コードをアプリケーション側で管理するか削除が必要。
現代の環境では携帯電話対応自体が不要なため、関連コードは積極的に削除を推奨。

### リスク 3: `ri_cal` → `icalendar` の互換性

API が大きく異なるため、カレンダー関連機能（スケジュール、iCal エクスポート等）の
リグレッションテストが必要。

### リスク 4: テストの不在

自動テストが存在しないため、各フェーズの動作確認はすべて手動になり、
リグレッションのリスクが高い。**フェーズ 0 でのテスト基盤整備を強く推奨する。**

### リスク 5: Ruby 4 は現時点で未リリース

フェーズ 7 は Rails 8 + Ruby 3.x で安定稼働してから取り組む。
リリース予定や破壊的変更は Ruby の公式アナウンスを随時確認すること。

---

## 推奨アプローチ

段階的な本番リリース（feature branch 戦略）を取り、**各フェーズ完了後に本番へマージ・
動作確認**を繰り返すことを推奨する。一括移行は失敗リスクが非常に高い。

特に工数がかかる箇所：

- **動的ファインダー 1,000+ 件の書き換え** → 半自動化スクリプトで対応推奨
- **Zeitwerk 対応** → `lib/` 配下のディレクトリ構造の整理
- **CoffeeScript → JavaScript の変換** → `decaffeinate` ツール活用
- **`Core` クラスのスレッドセーフ対応** → 全モジュールへの影響確認が必要
