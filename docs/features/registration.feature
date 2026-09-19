Feature: 申し込み
  参加者として
  興味のある勉強会の参加枠に申し込みたい
  当日に参加するため

  Background:
    Given 現在時刻は "2026-09-20T12:00+09:00" である
    And 主催者 "alice" が勉強会 "EDA入門" を公開している
      | 開催日時                | 募集締切                | キャンセル期限          |
      | 2026-10-05T19:00+09:00 | 2026-10-05T12:00+09:00 | 2026-10-04T19:00+09:00 |
    And "EDA入門" には次の参加枠がある
      | 参加枠  | 定員 |
      | 一般枠  | 10  |
      | LT枠    | 3   |
      | 学生枠  | 5   |

  Scenario: 空きのある参加枠に申し込む
    Given "一般枠" の参加確定者は 5 人である
    When "bob" が "一般枠" に申し込む
    Then "bob" の申込は Confirmed になる
    And "一般枠" の残席は 4 である
    And ReservationConfirmed イベントが発行される
      | 勉強会  | 参加枠 | 参加者 | reason     |
      | EDA入門 | 一般枠 | bob    | first_come |

  Scenario: 定員は参加枠ごとに独立している
    Given "一般枠" は満席である
    And "LT枠" の参加確定者は 0 人である
    When "bob" が "LT枠" に申し込む
    Then "bob" の申込は Confirmed になる
    And "一般枠" の残席は 0 のままである

  Scenario: 満席の参加枠に申し込むと補欠になる
    Given "LT枠" は満席である
    When "bob" が "LT枠" に申し込む
    Then "bob" の申込は Waitlisted になる
    And "bob" の補欠順位は 1 である
    And WaitlistEntryAdded イベントが発行される
    And ReservationConfirmed イベントは発行されない

  Scenario: 同じ勉強会の別の参加枠には重複して申し込めない
    Given "bob" は "一般枠" に Confirmed で申し込んでいる
    When "bob" が "LT枠" に申し込む
    Then 申込は受け付けられない
    And 理由は "この勉強会にはすでに申し込み済み" である
    And イベントは発行されない

  Scenario: 補欠で並んでいる間も別の枠には申し込めない
    Given "bob" は "LT枠" に Waitlisted で並んでいる
    When "bob" が "一般枠" に申し込む
    Then 申込は受け付けられない

  Scenario: キャンセル後は同じ勉強会に申し込み直せる
    Given "bob" は "一般枠" の申込をキャンセルしている
    When "bob" が "LT枠" に申し込む
    Then "bob" の申込は Confirmed になる

  Scenario: 募集締切を過ぎたら申し込めない
    Given 現在時刻は "2026-10-05T13:00+09:00" である
    When "bob" が "一般枠" に申し込む
    Then 申込は受け付けられない
    And 理由は "募集終了" である

  Scenario: 未公開の勉強会には申し込めない
    Given 勉強会 "非公開の勉強会" は Draft である
    When "bob" が "非公開の勉強会" の "一般枠" に申し込む
    Then 申込は受け付けられない

  Scenario: 中止された勉強会には申し込めない
    Given "EDA入門" は中止されている
    When "bob" が "一般枠" に申し込む
    Then 申込は受け付けられない
    And 理由は "この勉強会は中止されました" である

  Scenario Outline: 残席による申込結果
    Given "一般枠" の参加確定者は <確定者数> 人である
    When "bob" が "一般枠" に申し込む
    Then "bob" の申込は <結果> になる

    Examples:
      | 確定者数 | 結果       |
      | 8       | Confirmed  |
      | 9       | Confirmed  |
      | 10      | Waitlisted |

  # 定員という不変条件が競合下でも守られること
  Scenario: 最後の1席を2人が同時に申し込む
    Given "一般枠" の参加確定者は 9 人である
    When "bob" と "carol" が同時に "一般枠" に申し込む
    Then 1人が Confirmed、もう1人が Waitlisted になる
    And "一般枠" の参加確定者は 10 人を超えない
    And ReservationConfirmed イベントは 1 回だけ発行される

  Scenario: 同じ申込リクエストが再送される
    Given "一般枠" の参加確定者は 5 人である
    When "bob" がリクエストID "req-001" で "一般枠" に申し込む
    And 同じリクエストID "req-001" で再度申し込む
    Then "bob" の申込は 1 件である
    And "一般枠" の参加確定者は 6 人である
    And ReservationConfirmed イベントは 1 回だけ発行される
