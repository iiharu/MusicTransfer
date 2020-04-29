# MusicTransfer
Transfers music and playlist to WALKMAN from Mac Music.app

## TODO/BUG
- [TODO] エラー処理
    - エラーダイアログを表示する?
    - ロジッククラスからのエラーをハンドルして、ダイアログを表示する感じか?
- [TODO] ロジックとUIの分離
    - View -> UI, Bridge -> UIとLogic間の橋渡し, Logic -> 実際の処理を行うくらいに分けたい. エラー処理とかも楽になりそう.
- [FEATURE]　プログレスバー
- [FEATURE] アーティスト、アルバム、曲、プレイリストなどを指定して転送
    - 起動時にメディアをスキャン
    - アーティスト、アルバム、曲は木構造、プレイリストはリストを構築
    - それぞれに対して、フラグを設定し、UI側で設定できるようにする

## 更新履歴
- アーティスト名、アルバム名に`:`を含んでいる場合にエスケープ処理がされておらず、正常にプレイリストに追加されない問題を修正 ([c701aef](https://github.com/iiharu/MusicTransfer/commit/c701aefec5c7217e90b45e729221f5c9c4f245ab))
- コピー先とコピー元の更新日時の差に応じて処理を変更 ([98300f3](https://github.com/iiharu/MusicTransfer/commit/98300f38d88ca31a6f7851f1396d25e8cb36ba3e))
- 整理済み以外のライブラリに対応　([04713d8](https://github.com/iiharu/MusicTransfer/commit/04713d8ba74949dc47e8ddd6af34393775eb48f6), [072fff1](https://github.com/iiharu/MusicTransfer/commit/072fff1653fb39f683d21d4be026978020f90bc0))
- 濁点、半濁点をアーティスト、アルバム、曲名のいずれかに含む曲がプレイリストに含んでいると認識されない問題を修正 ([74abc95](https://github.com/iiharu/MusicTransfer/commit/74abc958c17ee4827ecdb1ac89909a4ed66bddb8))

