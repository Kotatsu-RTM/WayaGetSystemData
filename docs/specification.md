# WayaGetSystemData プログラム仕様書

## 1. 概要

`WayaGetSystemData`は、ホストマシンのシステム情報をHTTP経由で提供するWebアプリケーションです。Node.jsとTypeScriptで開発されており、`systeminformation`ライブラリと`fastfetch`コマンドを利用して各種システム情報を取得します。APIリクエスト時に取得したい情報の種類や出力形式を指定できる柔軟性を持っています。

## 2. アーキテクチャ

Fastifyフレームワークをベースに構築されており、軽量かつ高速なAPIサービスを提供します。システム情報の取得は、`systeminformation`ライブラリのAPI呼び出し、または`child_process`モジュールを介した`fastfetch`コマンドの実行によって行われます。

```mermaid
graph TD
    A[クライアント] -->|HTTPリクエスト| B(WayaGetSystemDataアプリケーション)
    B -->|APIエンドポイント| C{Fastifyサーバー}
    C -->|/api/systeminfo| D[systeminformationライブラリ]
    C -->|/api/fastfetch| E[fastfetchコマンド (child_process経由)]
    D -->|システム情報取得| F[ホストOS]
    E -->|システム情報取得| F
    F -->|情報返却| D
    F -->|情報返却| E
    D -->|JSONデータ| C
    E -->|テキストデータ| C
    C -->|HTTPレスポンス| A
```

## 3. APIエンドポイント

### 3.1. `/api/systeminfo`

`systeminformation`ライブラリを使用して、ホストのシステム情報を取得します。

*   **メソッド**: `GET`
*   **クエリパラメータ**:
    *   `modules` (オプション): 取得したい情報のカテゴリをカンマ区切りで指定します。指定しない場合、`si.getStaticData()`で取得可能な全ての情報が返されます。
        *   `modules=list`を指定すると、利用可能なモジュールの一覧をJSON形式で取得できます。
        *   **利用可能なモジュール**: `systeminformation`ライブラリが提供する主要なモジュール名（例: `cpu`, `mem`, `os`, `disk`, `networkInterfaces`, `battery`, `users`, `processes`, `fsSize`, `blockDevices`, `usb`, `bluetooth`, `vboxInfo`, `dockerInfo`, `printers`, `audio`, `graphics`, `display`, `temp`, `currentLoad`, `fullLoad`, `cpuCurrentSpeed`, `cpuTemperature`, `memLayout`, `diskLayout`, `networkStats`, `networkConnections`, `inetLatency`, `services`, `processes`, `users`, `time`, `versions`, `system`, `bios`, `baseboard`, `chassis`, `cpu`, `mem`, `battery`, `graphics`, `osInfo`, `uuid`, `diskLayout`, `fsSize`, `blockDevices`, `usb`, `audio`, `vboxInfo`, `dockerInfo`, `printers`, `networkInterfaces`など）。詳細なリストは[systeminformation公式ドキュメント](https://systeminformation.io/)
        を参照してください。
*   **レスポンス形式**: JSON
*   **例**:
    *   全ての情報を取得:
        ```
        GET /api/systeminfo
        ```
    *   CPUとメモリの情報のみ取得:
        ```
        GET /api/systeminfo?modules=cpu,mem
        ```

### 3.2. `/api/fastfetch`

`fastfetch`コマンドの出力をパースして、システム情報を取得します。

*   **メソッド**: `GET`
*   **クエリパラメータ**:
    *   `modules` (オプション): 取得したい情報のカテゴリをカンマ区切りで指定します。指定しない場合、`fastfetch`のデフォルト出力が全て返されます。
        *   `modules=list`を指定すると、利用可能なモジュールの一覧をJSON形式で取得できます。
        *   **利用可能なモジュール**: `fastfetch --list-modules`コマンドで確認できるモジュール名（例: `CPU`, `Memory`, `Disk`, `OS`, `Host`, `Kernel`, `Uptime`, `Packages`, `Shell`, `Terminal`, `GPU`, `LocalIp`, `Swap`など）。
*   **レスポンス形式**: JSON
*   **例**:
    *   全ての情報を取得:
        ```
        GET /api/fastfetch
        ```
    *   CPUとメモリの情報のみ取得:
        ```
        GET /api/fastfetch?modules=CPU,Memory
        ```

## 4. 認証

環境変数`WGS_API_KEY`が設定されている場合、APIキーによる認証が有効になります。クライアントはHTTPリクエストの`Authorization`ヘッダーに`Bearer <API_KEY>`の形式でAPIキーを含める必要があります。APIキーが設定されていない場合、認証はスキップされます。

## 5. エラーハンドリング

*   **認証エラー**: APIキーが不正な場合、HTTPステータスコード`401 Unauthorized`と`{ message: 'Unauthorized' }`が返されます。
*   **内部サーバーエラー**: システム情報の取得に失敗した場合（例: `fastfetch`コマンドの実行失敗、`systeminformation`ライブラリのエラーなど）、HTTPステータスコード`500 Internal Server Error`とエラーメッセージが返されます。

## 6. 起動・停止スクリプト

### 6.1. `start.sh`

アプリケーションをバックグラウンドで起動し、プロセスIDを`app.pid`ファイルに保存します。起動時の標準出力と標準エラー出力は`server.log`にリダイレクトされます。

### 6.2. `stop.sh`

`app.pid`ファイルに記録されたプロセスIDを使用してアプリケーションを停止します。プロセスが正常に停止しなかった場合、`dist/index.js`に関連するプロセスを検索し、その情報を表示します。

## 7. 開発環境

*   **言語**: TypeScript
*   **フレームワーク**: Fastify
*   **システム情報ライブラリ**: `systeminformation`
*   **外部コマンド**: `fastfetch`
*   **ビルドツール**: TypeScript Compiler (`tsc`)

## 8. 今後の展望

*   より詳細なエラーロギングと監視機能の追加。
*   APIレスポンスのキャッシュ機能の実装によるパフォーマンス向上。
*   設定ファイルによるAPIキーやポート番号の管理。
*   Dockerコンテナでの運用に関するドキュメントの拡充。
