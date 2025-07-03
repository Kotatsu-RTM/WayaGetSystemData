@echo off
chcp 65001 > nul

:: スクリプトの実行ディレクトリに移動
pushd "%~dp0"

:: 関数定義

:: fastfetchのインストールチェックとインストール
:check_and_install_fastfetch
    echo -----------------------------------------
    echo 1. fastfetchのインストールチェックとインストール
    echo -----------------------------------------
    where fastfetch > nul 2>&1
    if %errorlevel% equ 0 (
        echo fastfetchはすでにインストールされています。
    ) else (
        echo fastfetchはインストールされていません。インストールを開始します...
        echo fastfetchのインストールには管理者権限が必要です。
        echo.
        echo fastfetchのWindows用インストールは手動で行う必要があります。
        echo 以下のURLからインストーラーをダウンロードし、インストールしてください:
        echo https://github.com/fastfetch-cli/fastfetch/releases
        echo.
        pause
    )
    exit /b 0

:: Node.jsとnpmのインストールチェックとインストール
:check_and_install_nodejs_npm
    echo -----------------------------------------
    echo 2. Node.jsとnpmのインストールチェックとインストール
    echo -----------------------------------------
    where node > nul 2>&1
    if %errorlevel% equ 0 (
        where npm > nul 2>&1
        if %errorlevel% equ 0 (
            echo Node.jsとnpmはすでにインストールされています。
            for /f "tokens=*" %%i in ('node -v') do set "NODE_VERSION=%%i"
            for /f "tokens=*" %%i in ('npm -v') do set "NPM_VERSION=%%i"
            echo Node.jsバージョン: %NODE_VERSION%
            echo npmバージョン: %NPM_VERSION%
        ) else (
            echo npmはインストールされていません。Node.jsのインストールを確認してください。
        )
    ) else (
        echo Node.jsとnpmはインストールされていません。インストールを開始します...
        echo Node.jsとnpmのインストールには管理者権限が必要です。
        echo.
        echo Node.jsのWindows用インストーラーをダウンロードし、インストールしてください。
        echo 以下のURLから推奨版をダウンロードしてください:
        echo https://nodejs.org/ja/download/
        echo.
        pause
    )
    exit /b 0

:: APIキーの生成
:generate_api_key
    echo -----------------------------------------
    echo 3. APIキーの生成
    echo -----------------------------------------
    where openssl > nul 2>&1
    if %errorlevel% neq 0 (
        echo opensslがインストールされていません。APIキーの生成にはopensslが必要です。
        echo opensslをインストールしますか？ (y/n)
        set /p install_openssl_response=
        if /i "%install_openssl_response%"=="y" (
            echo opensslのWindows用インストールは手動で行う必要があります。
            echo 以下のURLからダウンロードし、インストールしてください:
            echo https://wiki.openssl.org/index.php/Binaries
            echo.
            pause
        ) else (
            echo opensslがインストールされていないため、APIキーを生成できません。
            exit /b 1
        )
    )

    for /f "tokens=*" %%i in ('openssl rand -base64 32') do set "API_KEY=%%i"
    echo 生成されたAPIキー: %API_KEY%
    echo このAPIキーを.envファイルに保存しますか？ (y/n)
    set /p response=
    if /i "%response%"=="y" (
        echo WGS_API_KEY="%API_KEY%" > ..\.env
        echo APIキーが.envファイルに保存されました。
        echo 注意: .envファイルはGit管理から除外されていますが、取り扱いには十分注意してください。
    ) else (
        echo APIキーは保存されませんでした。必要に応じて手動で設定してください。
    )
    exit /b 0

:: 依存関係のインストールとプロジェクトのビルド
:install_dependencies_and_build
    echo -----------------------------------------
    echo 4. 依存関係のインストールとプロジェクトのビルド
    echo -----------------------------------------
    where npm > nul 2>&1
    if %errorlevel% neq 0 (
        echo npmがインストールされていません。Node.jsとnpmを先にインストールしてください。
        exit /b 1
    )
    echo npm依存関係をインストールしています...
    npm install
    if %errorlevel% neq 0 (
        echo npm依存関係のインストールに失敗しました。
        exit /b 1
    )
    echo プロジェクトをビルドしています...
    npm run build
    if %errorlevel% neq 0 (
        echo プロジェクトのビルドに失敗しました。
        exit /b 1
    )
    echo 依存関係のインストールとプロジェクトのビルドが正常に完了しました。
    exit /b 0

:: 依存関係の更新
:update_dependencies
    echo -----------------------------------------
    echo 5. 依存関係の更新
    echo -----------------------------------------
    where npm > nul 2>&1
    if %errorlevel% neq 0 (
        echo npmがインストールされていません。Node.jsとnpmを先にインストールしてください。
        exit /b 1
    )
    echo npm依存関係を更新しています...
    npm update
    if %errorlevel% neq 0 (
        echo npm依存関係の更新に失敗しました。
        exit /b 1
    )
    echo 依存関係の更新が正常に完了しました。
    exit /b 0

:: メインメニュー
:show_menu
    echo.
    echo -----------------------------------------
    echo WayaGetSystemData 初期設定スクリプト
    echo -----------------------------------------
    echo 実行したい操作を選択してください:
    echo 1. fastfetchのインストールチェックとインストール
    echo 2. Node.jsとnpmのインストールチェックとインストール
    echo 3. APIキーの生成
    echo 4. 依存関係のインストールとプロジェクトのビルド
    echo 5. 依存関係の更新
    echo 0. 終了
    echo -----------------------------------------
    set /p choice="選択肢を入力してください (0-5): "

:: メインロジック
:main_loop
    call :show_menu
    if "%choice%"=="1" call :check_and_install_fastfetch
    if "%choice%"=="2" call :check_and_install_nodejs_npm
    if "%choice%"=="3" call :generate_api_key
    if "%choice%"=="4" call :install_dependencies_and_build
    if "%choice%"=="5" call :update_dependencies
    if "%choice%"=="0" goto :eof
    if not "%choice%"=="1" if not "%choice%"=="2" if not "%choice%"=="3" if not "%choice%"=="4" if not "%choice%"=="5" if not "%choice%"=="0" (
        echo 無効な選択です。もう一度入力してください。
    )
    echo.
goto :main_loop

:eof
echo スクリプトを終了します。
popd
