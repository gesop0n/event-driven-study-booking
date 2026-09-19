Feature: 勉強会の運営
  主催者として
  勉強会を公開し、必要なら中止したい
  参加者に正しい情報を届けるため

  Background:
    Given 現在時刻は "2026-09-20T12:00+09:00" である
    And 主催者 "alice" が勉強会 "EDA入門" を作成している

  Scenario: 勉強会を公開すると募集が始まる
    Given "EDA入門" は Draft である
    When "alice" が "EDA入門" を公開する
    Then "EDA入門" は Published になる
    And StudySessionPublished イベントが発行される
    And 勉強会一覧に "EDA入門" が表示される

  Scenario: 参加枠のない勉強会は公開できない
    Given "EDA入門" には参加枠が 1 つもない
    When "alice" が "EDA入門" を公開する
    Then 公開は拒否される

  Scenario: 主催者以外は勉強会を編集できない
    When "bob" が "EDA入門" の定員を変更しようとする
    Then 操作は拒否される

  # 1つのイベントから大量の処理が派生する（ファンアウト）
  Scenario: 勉強会の中止で申込と補欠がすべて解消される
    Given "EDA入門" は公開されている
    And "一般枠" に 7 件の Confirmed 申込がある
    And "一般枠" に 3 人の補欠が並んでいる
    When "alice" が "EDA入門" を中止する
    Then "EDA入門" は Cancelled になる
    And StudySessionCancelled イベントが発行される
    And 7 件の申込が Cancelled になる
    And 3 人の補欠が解消される
    And 10 人全員に中止通知が送られる

  # SeatReleased を統一イベントにしたことで生まれる罠
  Scenario: 中止では繰り上げ処理が走らない
    Given "EDA入門" は公開されている
    And "LT枠" は満席で、3 人の補欠が並んでいる
    When "alice" が "EDA入門" を中止する
    Then SeatReleased イベントは発行されない
    And WaitlistPromoted イベントは発行されない
    And 補欠の誰も Confirmed にならない

  Scenario: 中止済みの勉強会は再度中止できない
    Given "EDA入門" は中止されている
    When "alice" が "EDA入門" を中止する
    Then 操作は拒否される
    And StudySessionCancelled イベントは追加で発行されない

  Scenario: 主催者は参加者と補欠を確認できる
    Given "一般枠" に 2 人の Confirmed 申込と 1 人の補欠がある
    When "alice" が "EDA入門" の参加者一覧を開く
    Then 参加確定者が 2 人表示される
    And 補欠が順位付きで 1 人表示される
