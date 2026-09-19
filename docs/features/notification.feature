# 購読側の振る舞い。ドメイン処理とは別プロセスで動く前提で書く。
Feature: 通知
  参加者として
  自分の申し込み状況の変化を知りたい
  サイトを見に行かなくても把握するため

  Scenario Outline: 確定理由によって通知の文面が変わる
    When reason が "<reason>" の ReservationConfirmed イベントを受信する
    Then 参加者に "<件名>" のメールが送られる

    Examples:
      | reason            | 件名                   |
      | first_come        | 参加が確定しました        |
      | waitlist_promoted | 補欠から繰り上がりました   |

  Scenario: 補欠になったことを順位とともに知らせる
    When WaitlistEntryAdded イベントを受信する
      | 参加者 | 補欠順位 |
      | carol | 3       |
    Then "carol" に "補欠 3 番目で登録されました" というメールが送られる

  Scenario: 勉強会の中止を全員に知らせる
    When StudySessionCancelled イベントを受信する
    Then 参加確定者と補欠の全員に中止通知が送られる

  # at-least-once 配送の前提。購読者は必ず冪等でなければならない
  Scenario: 同じイベントを重複受信しても副作用は1回
    Given ReservationConfirmed イベント "evt-001" を処理済みである
    When 同じイベント "evt-001" を再度受信する
    Then 追加のメールは送信されない

  Scenario: 送信に失敗したイベントは再試行される
    Given メール送信が 2 回失敗したあと成功する
    When ReservationConfirmed イベントを受信する
    Then 3 回目で送信に成功する
    And 送信されたメールは 1 通である

  Scenario: 再試行しきれないイベントは DLQ に退避される
    Given メール送信が継続的に失敗する
    When ReservationConfirmed イベントを受信する
    Then 最大 3 回まで再試行される
    And 3 回失敗したら DLQ に退避される
    And 後続のイベント処理は止まらない

  Scenario: 通知の失敗はドメイン処理に影響しない
    Given メール送信が継続的に失敗する
    When "bob" が "一般枠" に申し込む
    Then "bob" の申込は Confirmed のままである
