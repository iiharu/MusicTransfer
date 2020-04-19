# MusicTransfer
Transfers music and playlist to WALKMAN from Mac Music.app

## 既知の問題
- メディアフォルダが整理されていないと曲ファイルを見つけることができない
- iTunes.appの元で整理されていた場合は見つけることができない
- ~~濁点、半濁点をアーティスト、アルバム名、曲名にいずれかに含むファイルが正常にプレイリストに登録されない~~ (修正済み: [74abc95](https://github.com/iiharu/MusicTransfer/commit/74abc958c17ee4827ecdb1ac89909a4ed66bddb8))

### TODO
- プログレスバー
- プレイリストを選択
- 未整理ライブラリに対応
  - `:`がアーティスト、アルバム名、曲名に含まれている場合の対応.
