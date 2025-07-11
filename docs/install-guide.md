# WayaGetSystemData (ホスト実行版)

## ざっくり仕様

`WayaGetSystemData` はNode.jsで開発されたWebアプリケーションです。  
HTTPリクエストを受け取ると、システム情報取得モジュール（`systeminformation`）や `fastfetch` コマンドを実行し、その結果をJSON形式などで返却します。

このホスト実行版では、以下のスクリプトを使用してアプリケーションの起動と停止を簡素化しています。

* `scripts/start.sh`: アプリケーションをバックグラウンドで起動し、そのプロセスID (PID) を `app.pid` ファイルに保存します。
* `scripts/stop.sh`: `app.pid` ファイルに保存されたPIDを読み込み、対応するプロセスを終了させます。

## 導入手順

`WayaGetSystemData`の導入と初期設定を簡素化するために、`init.sh` (Linux/macOS用) および `init.bat` (Windows用) スクリプトが用意されています。  
これらのスクリプトは、fastfetchやNode.js/npmのインストールチェック、APIキーの生成、依存関係のインストールとビルド、依存関係の更新といった一般的な初期設定タスクを対話形式で実行できます。

---

### **利用方法**

* **Linux/macOS**: アプリケーションのルートディレクトリで `./scripts/init.sh` を実行します。
* **Windows**: アプリケーションのルートディレクトリで `scripts\init.bat` を実行します。

スクリプトの指示に従って、必要な操作を選択してください。

---

### 1. **前提条件**

* Node.js (v18以上推奨) と npm がインストールされていること。
* `fastfetch`コマンドがホストマシンにインストールされており、パスが通っていること。  
  ※これらの前提条件は、`init.sh` (Linux/macOS) または `init.bat` (Windows) スクリプトを使用することで自動的にチェックおよびインストールできます。

---

### 2. **APIキーの設定 (推奨)**  

`WayaGetSystemData`は、APIへの不正アクセスを防ぐためにAPIキーによる認証をサポートしています。  
環境変数`WGS_API_KEY`、または `.env` ファイルにAPIキーを設定することで認証が有効になります。

#### APIキーの生成方法

APIキーは、推測されにくい十分に長くランダムな文字列を使用することが重要です。  
以下にいくつかの生成方法の候補を挙げます。

* **OpenSSLを使用する (推奨)**  

    暗号学的に安全なランダムな文字列を生成する最も一般的な方法です。Unix系OS (Linux, macOS) で広く利用可能です。Windowsでも、Git BashやWSL環境、または別途インストールすることで利用できます。

    ```bash
    openssl rand -base64 32
    # 例: 8s7d6f5g4h3j2k1l0p9o8i7u6y5t4r3e2w1q0a9s8d7f6g5h4j3k2l1m
    ```

* **Unix系OSの標準ツールを使用する**:

    LinuxやmacOSなどのUnix系OSで利用可能な標準コマンドを組み合わせる方法です。

    ```bash
    head /dev/urandom | tr -dc A-Za-z0-9_ | head -c 32
    # 例: aB1c2D3e4F5g6H7i8J9k0L1m2N3o4P5q6R7s8T9u0V1w2X3y4Z5
    ```

    **注意**: この方法はWindowsでは直接利用できません。

* **Windows PowerShellを使用する**:
    Windows環境でPowerShellを利用する場合の生成方法です。

    ```powershell
    # 32バイトのランダムなBase64文字列を生成
    [System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
    # 例: A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0U1V2W3X4Y5Z6==

    # または、よりシンプルなGUIDを生成 (ランダム性は高いが、Base64よりは短い)
    [System.Guid]::NewGuid().ToString()
    # 例: 12345678-abcd-efgh-ijkl-mnopqrstuvwx
    ```

#### **何をシークレットキーにするか？**  

上記の生成方法で得られるような、**十分に長く、ランダムで、予測不可能な文字列**をシークレットキーとして使用してください。  
誕生日、電話番号、簡単な単語の組み合わせなど、推測されやすいものは絶対に避けてください。

#### **設定方法**  

* **Unix系OS (Linux, macOS) での一時的な設定 (現在のシェルセッションのみ)**

    ```bash
    export WGS_API_KEY="YOUR_GENERATED_API_KEY"
    ```

* **Unix系OS (Linux, macOS) での永続的な設定 (推奨)**

    `~/.bashrc`や`~/.profile`、またはsystemdサービスファイル（`ExecStart`の前に`Environment="WGS_API_KEY=YOUR_GENERATED_API_KEY"`を追加）にAPIキーを設定します。

    ```bash
    export WGS_API_KEY="YOUR_GENERATED_API_KEY"
    ```

    変更を適用するために、シェルを再起動するか、`source ~/.bashrc`などを実行してください。

#### **Windowsでの一時的な設定 (現在のコマンドプロンプト/PowerShellセッションのみ)**

* **コマンドプロンプト**:

    ```cmd
    set WGS_API_KEY=YOUR_GENERATED_API_KEY
    ```

* **PowerShell**:

    ```powershell
    $env:WGS_API_KEY="YOUR_GENERATED_API_KEY"
    ```

**Windowsでの永続的な設定 (推奨)**:  

システム環境変数として設定することで、再起動後も有効になります。

1. 「システムのプロパティ」を開きます（Windowsキー + Pause/Breakキー、または「PC」を右クリックして「プロパティ」を選択）。
2. 「システムの詳細設定」をクリックします。
3. 「環境変数」ボタンをクリックします。
4. 「システム環境変数」または「ユーザー環境変数」セクションで「新規」をクリックし、変数名に`WGS_API_KEY`、変数値に生成したAPIキーを設定します。
5. 設定後、新しいコマンドプロンプトまたはPowerShellを開いて変更を適用します。

    **注意**: `WGS_API_KEY`が設定されていない場合、認証はスキップされます。  
    本番環境では必ずAPIキーを設定してください。

---

### 3.  **アプリケーションの取得**

`WayaGetSystemData`のソースコードをダウンロードまたはクローンします。

```bash
git clone https://github.com/Kotatsu-RTM/WayaGetSystemData.git
cd WayaGetSystemData
```

**注意**: このREADMEは、`WayaGetSystemData`ディレクトリでの検証を前提としています。  
実際の運用時、別名称へ変更している場合、変更後のディレクトリ名を使用してください。

1. **依存関係のインストール**

    アプリケーションのルートディレクトリで、必要なnpmパッケージをインストールします。

    ```bash
    npm install
    ```

2. **アプリケーションのビルド**

    TypeScriptコードをJavaScriptにコンパイルします。

    ```bash
    npm run build
    ```

3. **起動/停止スクリプトの配置**

    以下の内容で`start.sh`と`stop.sh`ファイルをアプリケーションのルートディレクトリに作成し、実行権限を付与します。

    **`start.sh`**

    ```bash
    #!/bin/bash
    echo "Starting WayaGetSystemData..."
    nohup node dist/index.js > /dev/null 2>&1 &
    echo $! > app.pid
    echo "WayaGetSystemData started with PID $!."
    echo "Access it via: curl http://localhost:3000/systeminfo"
    ```

    **`stop.sh`**

    ```bash
    #!/bin/bash
    if [ -f app.pid ]; then
      PID=$(cat app.pid)
      echo "Stopping WayaGetSystemData (PID: $PID)..."
      if kill $PID; then
        rm app.pid
        echo "WayaGetSystemData stopped."
      else
        echo "Failed to stop WayaGetSystemData (PID: $PID). Process might not be running."
        rm app.pid # PIDファイルが残っている場合は削除
      fi
    else
      echo "WayaGetSystemData is not running or app.pid not found."
    fi
    ```

    実行権限の付与

    ```bash
    chmod +x scripts/*.sh
    ```

---

## 運用手順

### APIエンドポイント

`WayaGetSystemData`は以下のAPIエンドポイントを提供します。

* `/api/systeminfo`: `systeminformation`モジュールを使用して、詳細なシステム情報をJSON形式で返します。

  * **単体で使う場合の例**:

    ```bash
    curl http://localhost:3000/api/systeminfo
    ```

  * **必要情報を指定したいときの例**:

    `modules`クエリパラメータを指定することで、取得する情報を絞り込むことができます。

    * 例: `/api/systeminfo?modules=cpu,mem,os`
    * `modules=list`を指定すると、利用可能なモジュールの一覧をJSON形式で取得できます。  
    * 利用可能なモジュールは`systeminformation`ライブラリのドキュメントを参照してください。主要なモジュールには`cpu`, `mem`, `os`, `disk`, `networkInterfaces`, `battery`, `users`などがあります。

      ```bash
      curl "http://localhost:3000/api/systeminfo?modules=cpu,mem"
      ```

  * `/api/fastfetch`: `fastfetch`コマンドの出力を基に、システム情報をJSON形式で返します。
    * **単体で使う場合の例**:

      ```bash
      curl http://localhost:3000/api/fastfetch
      ```

    * **必要情報を指定したいときの例**:

      `modules`クエリパラメータを指定することで、取得する情報を絞り込むことができます。

      * 例: `/api/fastfetch?modules=CPU,Memory,Disk`
      * `modules=list`を指定すると、利用可能なモジュールの一覧をJSON形式で取得できます。
      * 利用可能なモジュールは`fastfetch --list-modules`コマンドで確認できます。主要なモジュールには`CPU`, `Memory`, `Disk`, `OS`, `Host`, `Kernel`, `Uptime`などがあります。

        ```bash
        curl "http://localhost:3000/api/fastfetch?modules=CPU,Memory"
        ```

---

### アプリケーションの起動

アプリケーションをバックグラウンドで起動します。

```bash
./scripts/start.sh
```

起動後、`http://localhost:3000/api/systeminfo` または `http://localhost:3000/api/fastfetch` にアクセスすることでシステム情報を取得できます。

**APIキーを使用したアクセス方法**:

`WGS_API_KEY`環境変数を設定している場合、APIキーをHTTPヘッダーに含めてリクエストを送信する必要があります。  
APIキーをURLに含めることは、セキュリティ上のリスクがあるため、**絶対に避けてください**。

例:

```bash
# APIキーをHTTPヘッダーに含めてアクセス
curl -H "Authorization: Bearer YOUR_GENERATED_API_KEY" http://localhost:3000/api/systeminfo
curl -H "Authorization: Bearer YOUR_GENERATED_API_KEY" http://localhost:3000/api/fastfetch
curl -H "Authorization: Bearer YOUR_GENERATED_API_KEY" "http://localhost:3000/api/systeminfo?modules=cpu,mem"
curl -H "Authorization: Bearer YOUR_GENERATED_API_KEY" "http://localhost:3000/api/fastfetch?modules=CPU,Memory"
```

`YOUR_GENERATED_API_KEY`は、実際に設定したAPIキーに置き換えてください。

---

### アプリケーションの停止

起動中のアプリケーションを停止します。
```bash
./scripts/stop.sh
```

---

### Systemdサービスとしての運用 (推奨)

`WayaGetSystemData`をシステム起動時に自動的に起動し、バックグラウンドで安定して動作させるために、systemdサービスとして登録することを推奨します。

1. **サービスファイルの作成**:

    `/etc/systemd/system/WayaGetSystemData.service`という名前で以下の内容のファイルを作成します。  
    `ExecStart`と`WorkingDirectory`のパスは、`WayaGetSystemData`アプリケーションが配置されている実際のパスに合わせてください。

    ```ini
    [Unit]
    Description=WayaGetSystemData Service
    After=network.target

    [Service]
    Type=simple
    User=<your_username> # アプリケーションを実行するユーザー名に置き換えてください
    WorkingDirectory=/path/to/your/WayaGetSystemData # WayaGetSystemDataディレクトリの絶対パスに置き換えてください
    ExecStart=/usr/bin/npm start
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    ```

2. **systemdの再読み込み**:

    サービスファイルを作成または変更した後は、systemdに設定を再読み込みさせます。

    ```bash
    sudo systemctl daemon-reload
    ```

3. **サービスの有効化と起動**:

    システム起動時にサービスが自動的に起動するように有効化し、すぐにサービスを起動します。

    ```bash
    sudo systemctl enable WayaGetSystemData.service
    sudo systemctl start WayaGetSystemData.service
    ```

4. **サービスのステータス確認**:

    サービスが正常に動作しているか確認します。

    ```bash
    systemctl status WayaGetSystemData.service
    ```

5. **サービスの停止と無効化**:

    サービスを停止し、システム起動時の自動起動を無効にするには、以下のコマンドを使用します。

    ```bash
    sudo systemctl stop WayaGetSystemData.service
    sudo systemctl disable WayaGetSystemData.service
    ```

    サービスファイルを削除する場合は、無効化後に削除し、`sudo systemctl daemon-reload`を実行してください。

    ```bash
    sudo rm /etc/systemd/system/WayaGetSystemData.service
    sudo systemctl daemon-reload
    ```

---

### ログの確認

`WayaGetSystemData`サービスは、systemdのジャーナル機能を利用してログを記録します。  
これにより、サービスの起動・停止、異常終了、およびアプリケーションへのアクセス履歴を確認できます。

1. **サービスの起動・停止・異常終了ログの確認**:

    `journalctl`コマンドを使用して、サービスのログを確認できます。

    ```bash
    journalctl -u WayaGetSystemData.service
    ```

    リアルタイムでログを追跡するには、`-f`オプションを使用します。

    ```bash
    journalctl -u WayaGetSystemData.service -f
    ```

2. **アプリケーションへのアクセスログの確認**:

    `WayaGetSystemData`アプリケーションは、`fastify`のロギング機能により、各HTTPリクエストの情報を標準出力に出力します。これらのログもsystemdのジャーナルに記録されます。  
    `journalctl -u WayaGetSystemData.service`で確認できます。ログには、リクエストのメソッド、URL、クライアントIPアドレスなどが含まれます。

---

## 廃止手順

※daemonで管理している場合は、別途daemonの終了と、廃止をお願いします。

1. **アプリケーションの停止**:

    ```bash
    ./stop.sh
    ```

2. **アプリケーションディレクトリの削除**:

    アプリケーションのルートディレクトリ（例: `WayaGetSystemData`）を削除します。

    ```bash
    rm -rf WayaGetSystemData
    ```

3. **fastfetchのアンインストール (任意)**:

    `fastfetch`が不要になった場合は、アンインストールします。

    ```bash
    sudo apt-get purge fastfetch
    sudo add-apt-repository --remove ppa:zhangsongcui3371/fastfetch
    ```

---
