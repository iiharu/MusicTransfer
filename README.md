# MusicTransfer
Transfers music and playlist to WALKMAN from Mac Music.app

## TODO/BUG
- (BUG) ファイルの更新時間の差が1sになっているので、コピーされてしまう問題
- (TODO) エラー処理
- (TODO) ロジックとUIの分離
- (TODO) プログレスバー
- (TODO) プレイリストを選択
    - 転送時ではなく、アプリケーション開始時にメディア、プレイリストをスキャンして、メディア (ID -> (src, dst))、プレイリスト (name->ids) を構成する。

## 更新履歴
- 整理済み以外のライブラリに対応　([04713d8](https://github.com/iiharu/MusicTransfer/commit/04713d8ba74949dc47e8ddd6af34393775eb48f6), [072fff1](https://github.com/iiharu/MusicTransfer/commit/072fff1653fb39f683d21d4be026978020f90bc0))
- 濁点、半濁点をアーティスト、アルバム、曲名のいずれかに含む曲がプレイリストに含んでいると認識されない問題を修正 ([74abc95](https://github.com/iiharu/MusicTransfer/commit/74abc958c17ee4827ecdb1ac89909a4ed66bddb8))

