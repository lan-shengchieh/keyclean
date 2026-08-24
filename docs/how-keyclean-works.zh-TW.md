# keyclean 如何只鎖住 Mac 鍵盤並保留觸控板

`keyclean` 是一個只有單一 Swift 原始碼檔的 macOS 命令列工具。它利用
Core Graphics event tap 暫時攔截鍵盤輸入，不需要 kernel extension、
驅動程式、登入項目或背景服務。

## Event 流程

1. `keyclean` 在 session event-tap chain 的前端建立 `CGEventTap`。
2. Event mask 包含一般按鍵按下與放開、修飾鍵變化，以及這一層能看到的
   媒體鍵等 system-defined keyboard events。
3. Callback 對這些事件回傳 `nil`，讓它們不會繼續傳到目前的應用程式。
4. 按下 `Control + Option + Command + U` 時會停止 run loop，不會把這組
   按鍵傳遞出去。
5. 程式退出前會停用並移除 event tap；即使程序被終止，macOS 也會自動
   移除它。

完整實作都在 [keyclean.swift](../keyclean.swift)。

## 為什麼觸控板仍可使用

Event mask 刻意不包含滑鼠、游標、捲動與手勢事件。`keyclean` 不會占用
任何游標裝置，因此仍能用觸控板或滑鼠移動游標，必要時也能關閉 Terminal
視窗。

這也是專案刻意選擇的取捨：它是專注於鍵盤清潔的 CLI，而不是停用所有
輸入裝置的全螢幕模式。

## 為什麼需要「輔助使用」權限

macOS 會保護能攔截使用者輸入的 event tap，因此啟動 `keyclean` 的終端機
需要「輔助使用」權限。`keyclean` 不需要 `sudo`、管理員權限、「輸入監控」
權限或常駐 helper。

## 隱私與安全界線

- Callback 不會把 key code 轉成文字，也不會儲存輸入。
- 沒有網路程式碼、分析功能、設定檔或背景程序。
- `keyclean` 不是登入鎖、安全邊界或家長監護工具。
- Touch ID 與實體電源鍵在 event-tap 層之下，不在保證範圍內。
- 如果 macOS 因逾時暫時停用 event tap，`keyclean` 會將它重新啟用。

## 復原方式

下列任一方式都能恢復鍵盤輸入：

1. 按下 `Control + Option + Command + U`。
2. 用觸控板或滑鼠關閉執行 `keyclean` 的 Terminal 視窗。
3. 從另一個 session 終止 `keyclean` 程序。

這些方式都會讓程序結束並移除 event tap。

## 自行建置與檢查

```sh
git clone https://github.com/lan-shengchieh/keyclean.git
cd keyclean
make test
```

Homebrew Formula 也是直接編譯有版本標籤的 Swift 原始碼，不會下載預先
編譯的執行檔。
