# keyclean

[![CI](https://github.com/lan-shengchieh/keyclean/actions/workflows/ci.yml/badge.svg)](https://github.com/lan-shengchieh/keyclean/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/lan-shengchieh/keyclean)](https://github.com/lan-shengchieh/keyclean/releases/latest)
[![GitHub stars](https://img.shields.io/github/stars/lan-shengchieh/keyclean?style=flat)](https://github.com/lan-shengchieh/keyclean/stargazers)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[English](README.md)

![keyclean — Lock the keys. Keep the trackpad.](.github/social-preview.jpg)

鎖住鍵盤、保留觸控板，清潔 MacBook 時不再誤觸按鍵。

KeyClean 0.2 在 macOS 13 以上提供兩種刻意區分的安全模式：

- **Safe Mode** 是預設模式。它會覆蓋所有螢幕、丟棄送給 KeyClean 的
  鍵盤事件，而且完全不要求「輔助使用」權限。
- **Full Lock** 是明確選用的模式。它以 active Core Graphics event tap
  在系統範圍攔截鍵盤事件；「輔助使用」只授予獨立的 KeyClean app，
  不再授予 Terminal、iTerm2 或其他終端機。

兩種模式都保留游標，解鎖後便完整退出。沒有 daemon、登入項目、分析
追蹤、網路程式碼或儲存的輸入內容。

## 安裝

```sh
brew install lan-shengchieh/tap/keyclean
```

啟動不需權限的 Safe Mode：

```sh
keyclean
```

若要測試最新開發分支而非穩定版本，可使用：

```sh
brew install --HEAD lan-shengchieh/tap/keyclean
```

## 選擇模式

### Safe Mode——預設、不要求隱私權限

```sh
keyclean
# 或
keyclean --safe
```

Safe Mode 會在每個已連接螢幕建立清潔遮罩，並讓 KeyClean 保持前景。
一般按鍵與常見的 App 切換快捷鍵不會落入其他程式。使用觸控板／滑鼠
點擊 **Unlock Keyboard**，或按 **Control + Option + Command + U**
（`⌃⌥⌘U`）即可結束。

Safe Mode 是刻意採用的 application-level best effort：部分系統保留的
媒體鍵、Touch ID 和實體電源鍵仍可能生效。

### Full Lock——選用「輔助使用」權限

```sh
keyclean --full
```

Full Lock 透過 active `CGEventTap` 攔截鍵盤、修飾鍵與 event tap 可見的
媒體鍵；小型置頂面板不會妨礙你用觸控板或滑鼠操作其他 App。

第一次使用時，請按 **Open System Settings**，再於下列位置啟用
**KeyClean Full Lock**，而不是你的終端機：

**系統設定 → 隱私權與安全性 → 輔助使用**

完成後回到 KeyClean；App 重新成為作用中程式時會自動檢查權限並開始
Full Lock，不需要手動重試。

「輔助使用」是 macOS 的廣泛權限，並非只允許攔截鍵盤；KeyClean 無法
把系統權限切得更細。需要時可只撤銷 KeyClean Full Lock 的權限：

```sh
keyclean --revoke-full-access
```

若只想使用一次 Full Lock，並在 session 結束後立即自動撤銷 KeyClean
權限，可執行：

```sh
keyclean --full-once
```

下一次 Full Lock 會重新要求授權。只要等待中的 `keyclean` CLI 仍在執行，
按 Cancel 或 Full app crash 後也會自動撤銷。

## 安全模型

免費且可重現的 Homebrew 建置採 split layout：

| 元件 | TCC 權限 | 用途 |
| --- | --- | --- |
| `keyclean` CLI | 無 | 透過 LaunchServices 啟動所選 app |
| `KeyClean.app` | 無 | 執行前景 Safe Mode 遮罩 |
| `KeyCleanFull.app` | 使用者同意後為「輔助使用」 | 執行系統範圍 active event tap |

這個分離確保 Full Lock 不會把「輔助使用」授予 Safe Mode app，更不會
授予終端機啟動的所有命令。同一時間只允許一個 KeyClean session，兩個
app 解鎖後都不會常駐。

Homebrew 會在本機編譯固定 tag 的原始碼，並套用 ad-hoc code signature，
讓 macOS 能檢查組裝後的 bundle 是否遭修改。Ad-hoc signing **不能**
驗證發布者，也不提供 notarization。正式版本只提供這個 split layout，
兩個 app 都不帶 entitlement。程式沒有網路程式碼，但此建置沒有由作業
系統強制執行「禁止網路」的界線。

Event flow、process attribution、權限界線與復原方式請見
[KeyClean 的運作原理](docs/how-keyclean-works.zh-TW.md)。

## 從 v0.1 升級

KeyClean 0.1 會要求終端機取得「輔助使用」。0.2 不再需要該終端機權限。
如果你只因 KeyClean 而啟用了 Terminal、iTerm2、Ghostty、Warp 或其他
終端機，升級後請到系統設定手動關閉。KeyClean 不會自動撤銷，因為其他
工作流程可能仍依賴該權限。

## 從原始碼建置

需求：macOS 13 以上，以及包含 Swift 5.7 以上的 Apple Command Line Tools。

```sh
git clone https://github.com/lan-shengchieh/keyclean.git
cd keyclean
make test
make cross-build
```

安裝到 `~/.local`：

```sh
make install
```

`make test` 不會開啟 UI 或要求隱私權限；它會執行單元測試、組裝免費
split bundle、驗證 property list 與 code signature，再執行兩個 app 的
self-test。

## 疑難排解

**Safe Mode 立即關閉**

Safe Mode 必須保持為作用中的 App 才能可靠丟棄事件。如果 macOS 把焦點
移走，KeyClean 會直接結束，而不會假裝鍵盤仍被鎖住。

**Full Lock 顯示缺少「輔助使用」**

在「輔助使用」中啟用 KeyClean Full Lock，接著回到 KeyClean，App 會自動
重新檢查。不要啟用終端機。

**授權後 Full Lock 仍不可用**

執行 `keyclean --revoke-full-access`，重新啟動 Full Lock，並在系統設定再次
授予 KeyClean Full Lock 權限。如果 active event tap 仍無法建立，請改用
Safe Mode。

**`--revoke-full-access` 顯示成功，但系統設定看起來沒有改變**

請關閉後重新開啟「系統設定」；TCC 畫面有時不會立即更新。如果畫面仍未
更新，請再次執行 `keyclean --revoke-full-access`。此指令會重設目前的 Full
Lock identity、早期 v0.2 的 KeyClean identity 與其舊版 `PostEvent` 決策，
不會重設終端機。

**鍵盤仍處於鎖定狀態**

點擊 **Unlock Keyboard** 或按 `⌃⌥⌘U`。終止 KeyClean app 也會讓 local
monitor 或 event tap 自動消失。

## 參與貢獻

歡迎回報錯誤、相容性結果與範圍明確的 pull request。測試與回報說明請見
[CONTRIBUTING.md](CONTRIBUTING.md)。

相容性報告請包含使用模式、macOS 版本、Mac 架構、終端機，以及系統的
「輔助使用」清單中顯示的是 KeyClean 還是終端機。

## 授權

[MIT](LICENSE)
