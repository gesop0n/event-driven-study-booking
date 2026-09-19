Feature: 申し込みのキャンセル
  参加者として
  都合が悪くなった申し込みを取り消したい
  空いた席を他の人に譲るため

  Background:
    Given 現在時刻は "2026-09-20T12:00+09:00" である
    And 勉強会 "EDA入門" が公開されている
      | 開催日時                | キャンセル期限          |
      | 2026-10-05T19:00+09:00 | 2026-10-04T19:00+09:00 |
    And "bob" は "一般枠" に Confirmed で申し込んでいる

  Scenario: 参加確定をキャンセルする
    When "bob" が申込をキャンセルする
    Then "bob" の申込は Cancelled になる
    And ReservationCancelled イベントが発行される
    And SeatReleased イベントが発行される
    And "bob" にキャンセル完了通知が送られる

  Scenario: キャンセル期限を過ぎたらキャンセルできない
    Given 現在時刻は "2026-10-04T20:00+09:00" である
    When "bob" が申込をキャンセルする
    Then キャンセルは拒否される
    And 理由は "キャンセル期限を過ぎています" である
    And "bob" の申込は Confirmed のままである
    And イベントは発行されない

  Scenario: 他人の申込はキャンセルできない
    When "carol" が "bob" の申込をキャンセルしようとする
    Then 操作は拒否される
    And "bob" の申込は Confirmed のままである

  Scenario: すでにキャンセル済みの申込は再度キャンセルできない
    Given "bob" は申込をキャンセルしている
    When "bob" が同じ申込をキャンセルする
    Then キャンセルは拒否される
    And ReservationCancelled イベントは追加で発行されない
    And SeatReleased イベントは追加で発行されない

  Scenario: 同じキャンセルリクエストが再送される
    When "bob" がリクエストID "req-002" で申込をキャンセルする
    And 同じリクエストID "req-002" で再度キャンセルする
    Then ReservationCancelled イベントは 1 回だけ発行される
    And "一般枠" の残席は 1 しか増えない
