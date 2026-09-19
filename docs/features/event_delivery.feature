# ブローカー実装（in-memory / Redis Streams / Kafka）を差し替えても
# 同じシナリオが通ることを確認するための feature。
Feature: イベントの配送

  Scenario: DB更新とイベント発行は原子的である
    Given ブローカーが停止している
    When "bob" が "一般枠" に申し込む
    Then "bob" の申込は Confirmed で保存される
    And ReservationConfirmed が outbox に記録される
    And ブローカー復旧後にイベントが発行される

  Scenario: コミットされなかったイベントは発行されない
    Given 申込の保存がトランザクション内で失敗する
    When "bob" が "一般枠" に申し込む
    Then 申込は保存されない
    And ReservationConfirmed イベントは発行されない

  @at-least-once
  Scenario: 同じイベントが複数回配送されても状態は1回分しか変わらない
    Given SeatReleased イベント "evt-001" を処理済みである
    When 同じイベント "evt-001" を再度受信する
    Then 繰り上げ処理は追加で実行されない

  # 購読者は原則として順序に依存しない実装にする
  Scenario: イベントが逆順に届いても最終状態は同じ
    Given "bob" のキャンセルで ReservationCancelled と SeatReleased が発行されている
    When 購読者が SeatReleased を先に受信する
    And その後 ReservationCancelled を受信する
    Then 最終的に "carol" が繰り上げられている
    And 通知はそれぞれ 1 通だけ送られる

  # Kafka（key = 勉強会ID）では通り、Redis Streams の並列コンシューマでは崩れる
  @ordering-required
  Scenario: 同一勉強会のイベントは発行順に処理される
    Given "EDA入門" に対して 3 件のイベントが順に発行されている
    When 購読者がそれらを処理する
    Then 発行順と同じ順序で処理される

  Scenario: 異なる勉強会のイベントは並行に処理できる
    Given "EDA入門" と "DDD入門" にそれぞれイベントが発行されている
    When 購読者が処理する
    Then 互いの処理は待ち合わせない

  Scenario: 処理に失敗したイベントが後続を止めない
    Given "evt-001" の処理が必ず失敗する
    And "evt-002" は正常に処理できる
    When 両方のイベントを受信する
    Then "evt-001" は DLQ に退避される
    And "evt-002" は正常に処理される

  Scenario: DLQ のイベントは再投入できる
    Given "evt-001" が DLQ に退避されている
    And 失敗の原因が解消されている
    When "evt-001" を再投入する
    Then 正常に処理される
