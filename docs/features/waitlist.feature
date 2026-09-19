Feature: 補欠と繰り上げ
  満席で申し込めなかった参加者として
  キャンセルが出たら自動で繰り上がりたい
  申し込み直す手間をかけずに参加するため

  Background:
    Given 勉強会 "EDA入門" が公開されている
    And "LT枠" の定員は 3 人で、参加確定者は "alice" "bob" "frank" である
    And "LT枠" の補欠は次の通りである
      | 順位 | 参加者 |
      | 1   | carol |
      | 2   | dave  |
      | 3   | erin  |

  Scenario: キャンセルで補欠の先頭が自動的に繰り上がる
    When "bob" が申込をキャンセルする
    Then ReservationCancelled イベントが発行される
    And SeatReleased イベントが発行される
    And "carol" の申込は Confirmed になる
    And WaitlistPromoted イベントが発行される
    And ReservationConfirmed イベントが発行される
      | 勉強会  | 参加枠 | 参加者 | reason             |
      | EDA入門 | LT枠   | carol  | waitlist_promoted  |

  Scenario: 繰り上げ後に補欠順位が詰められる
    When "bob" が申込をキャンセルする
    Then "LT枠" の補欠は次の通りになる
      | 順位 | 参加者 |
      | 1   | dave  |
      | 2   | erin  |

  Scenario: 補欠自身のキャンセルでは繰り上げは起きない
    When "dave" が申込をキャンセルする
    Then "LT枠" の補欠は次の通りになる
      | 順位 | 参加者 |
      | 1   | carol |
      | 2   | erin  |
    And SeatReleased イベントは発行されない
    And WaitlistPromoted イベントは発行されない

  Scenario: 補欠がいない参加枠のキャンセルでは繰り上げが起きない
    Given "一般枠" の参加確定者は 5 人で、補欠はいない
    When "一般枠" の "bob" が申込をキャンセルする
    Then SeatReleased イベントが発行される
    And WaitlistPromoted イベントは発行されない
    And "一般枠" の残席が 1 増える

  Scenario: 定員を増やすと複数人が一度に繰り上がる
    When 主催者 "alice" が "LT枠" の定員を 5 人に変更する
    Then SeatReleased イベントが 2 回発行される
    And "carol" と "dave" が Confirmed になる
    And "erin" が補欠の 1 番目になる

  Scenario: 参加確定者数を下回る定員には変更できない
    When 主催者 "alice" が "LT枠" の定員を 2 人に変更する
    Then 変更は拒否される
    And 理由は "すでに 3 人の参加が確定しています" である

  Scenario: 募集終了後もキャンセルによる繰り上げは行われる
    Given 現在時刻は募集締切を過ぎている
    When "bob" が申込をキャンセルする
    Then "carol" の申込は Confirmed になる

  # at-least-once 配送により同じ SeatReleased が二重に届きうる
  Scenario: SeatReleased を重複受信しても繰り上がるのは1人だけ
    Given SeatReleased イベント "evt-001" で "carol" が繰り上げ済みである
    When 同じイベント "evt-001" を再度受信する
    Then "dave" は補欠の 1 番目のままである
    And WaitlistPromoted イベントは追加で発行されない

  Scenario: 補欠は枠をまたいで繰り上がらない
    Given "一般枠" に空席が 1 つある
    When "一般枠" の参加者がキャンセルする
    Then "LT枠" の補欠は誰も繰り上がらない
