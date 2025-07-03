#!/bin/bash

# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")" || exit

# 関数定義

# fastfetchのインストールチェックとインストール
check_and_install_fastfetch() {
    echo "-----------------------------------------"
    echo "1. fastfetchのインストールチェックとインストール"
    echo "-----------------------------------------"
    if command -v fastfetch &> /dev/null; then
        echo "fastfetchはすでにインストールされています。"
    else
        echo "fastfetchはインストールされていません。インストールを開始します..."
        echo "fastfetchのインストールにはsudo権限が必要です。パスワードを求められる場合があります。"
        # Ubuntu/Debianの場合
        if [ -f /etc/debian_version ]; then
            sudo apt-get update || { echo "apt-get updateに失敗しました。"; return 1; }
            sudo apt-get install -y software-properties-common || { echo "software-properties-commonのインストールに失敗しました。"; return 1; }
            sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y || { echo "fastfetch PPAの追加に失敗しました。"; return 1; }
            sudo apt-get update || { echo "apt-get updateに失敗しました。"; return 1; }
            sudo apt-get install -y fastfetch || { echo "fastfetchのインストールに失敗しました。"; return 1; }
        else
            echo "このOSは自動fastfetchインストールに対応していません。手動でインストールしてください。"
            return 1
        fi
        if command -v fastfetch &> /dev/null; then
            echo "fastfetchが正常にインストールされました。"
        else
            echo "fastfetchのインストールに失敗しました。"
            return 1
        fi
    fi
    return 0
}

# Node.jsとnpmのインストールチェックとインストール
check_and_install_nodejs_npm() {
    echo "-----------------------------------------"
    echo "2. Node.jsとnpmのインストールチェックとインストール"
    echo "-----------------------------------------"
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        echo "Node.jsとnpmはすでにインストールされています。"
        echo "Node.jsバージョン: $(node -v)"
        echo "npmバージョン: $(npm -v)"
    else
        echo "Node.jsとnpmはインストールされていません。インストールを開始します..."
        echo "Node.jsとnpmのインストールにはsudo権限が必要です。パスワードを求められる場合があります。"
        # Ubuntu/Debianの場合 (NodeSource PPAを使用)
        if [ -f /etc/debian_version ]; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || { echo "NodeSource PPAのセットアップに失敗しました。"; return 1; }
            sudo apt-get install -y nodejs || { echo "Node.jsのインストールに失敗しました。"; return 1; }
        else
            echo "このOSは自動Node.js/npmインストールに対応していません。手動でインストールしてください。"
            return 1
        fi
        if command -v node &> /dev/null && command -v npm &> /dev/null; then
            echo "Node.jsとnpmが正常にインストールされました。"
            echo "Node.jsバージョン: $(node -v)"
            echo "npmバージョン: $(npm -v)"
        else
            echo "Node.jsとnpmのインストールに失敗しました。"
            return 1
        fi
    fi
    return 0
}

# APIキーの生成
generate_api_key() {
    echo "-----------------------------------------"
    echo "3. APIキーの生成"
    echo "-----------------------------------------"
    if ! command -v openssl &> /dev/null; then
        echo "opensslがインストールされていません。APIキーの生成にはopensslが必要です。"
        echo "opensslをインストールしますか？ (y/n)"
        read -r install_openssl_response
        if [[ "$install_openssl_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            sudo apt-get update && sudo apt-get install -y openssl || { echo "opensslのインストールに失敗しました。"; return 1; }
        else
            echo "opensslがインストールされていないため、APIキーを生成できません。"
            return 1
        fi
    fi

    API_KEY=$(openssl rand -base64 32)
    echo "生成されたAPIキー: $API_KEY"
    echo "このAPIキーを.envファイルに保存しますか？ (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "WGS_API_KEY=\"$API_KEY\"" > ../.env
        echo "APIキーが.envファイルに保存されました。"
        echo "注意: .envファイルはGit管理から除外されていますが、取り扱いには十分注意してください。"
    else
        echo "APIキーは保存されませんでした。必要に応じて手動で設定してください。"
    fi
    return 0
}

# 依存関係のインストールとプロジェクトのビルド
install_dependencies_and_build() {
    echo "-----------------------------------------"
    echo "4. 依存関係のインストールとプロジェクトのビルド"
    echo "-----------------------------------------"
    if ! command -v npm &> /dev/null; then
        echo "npmがインストールされていません。Node.jsとnpmを先にインストールしてください。"
        return 1
    }
    echo "npm依存関係をインストールしています..."
    npm install || { echo "npm依存関係のインストールに失敗しました。"; return 1; }
    echo "プロジェクトをビルドしています..."
    npm run build || { echo "プロジェクトのビルドに失敗しました。"; return 1; }
    echo "依存関係のインストールとプロジェクトのビルドが正常に完了しました。"
    return 0
}

# 依存関係の更新
update_dependencies() {
    echo "-----------------------------------------"
    echo "5. 依存関係の更新"
    echo "-----------------------------------------"
    if ! command -v npm &> /dev/null; then
        echo "npmがインストールされていません。Node.jsとnpmを先にインストールしてください。"
        return 1
    }
    echo "npm依存関係を更新しています..."
    npm update || { echo "npm依存関係の更新に失敗しました。"; return 1; }
    echo "依存関係の更新が正常に完了しました。"
    return 0
}

# メインメニュー
show_menu() {
    echo ""
    echo "-----------------------------------------"
    echo "WayaGetSystemData 初期設定スクリプト"
    echo "-----------------------------------------"
    echo "実行したい操作を選択してください:"
    echo "1. fastfetchのインストールチェックとインストール"
    echo "2. Node.jsとnpmのインストールチェックとインストール"
    echo "3. APIキーの生成"
    echo "4. 依存関係のインストールとプロジェクトのビルド"
    echo "5. 依存関係の更新"
    echo "0. 終了"
    echo "-----------------------------------------"
    read -p "選択肢を入力してください (0-5): " choice
}

# メインロジック
while true; do
    show_menu
    case $choice in
        1) check_and_install_fastfetch ;;
        2) check_and_install_nodejs_npm ;;
        3) generate_api_key ;;
        4) install_dependencies_and_build ;;
        5) update_dependencies ;;
        0) echo "スクリプトを終了します。"; break ;;
        *) echo "無効な選択です。もう一度入力してください。" ;;
    esac
    echo "" # 空行
done
