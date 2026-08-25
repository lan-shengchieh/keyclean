# KeyClean 如何避免把「輔助使用」授予終端機

KeyClean 0.2 把不需權限的前景清潔模式，與選用的系統範圍鎖定模式分開。
兩者都由小型 CLI 透過 macOS LaunchServices 啟動，解鎖後完整退出。

## 程序配置

免費且可重現的建置會安裝三個元件：

```text
Terminal（無「輔助使用」）
  └─ keyclean CLI（無「輔助使用」）
       ├─ Safe Mode → KeyClean.app（無 TCC 權限）
       └─ Full Lock → KeyCleanFull.app（使用者同意後取得「輔助使用」）
```

CLI 使用 `NSWorkspace.openApplication`，而不是把 app binary 當成 Terminal
child 直接執行。macOS 因此能把 KeyClean app bundle 認定為隱私決策的
responsible code。CLI 會等待 app 結束，所以操作仍是 `keyclean` → 清潔 →
解鎖 → 回到 prompt。

同一時間只允許一個 KeyClean bundle identifier 對應的程序執行。

## Safe Mode event flow

1. `KeyClean.app` 成為作用中的 App，並為每個 `NSScreen` 建立無邊框遮罩。
2. App presentation options 暫時隱藏 Dock 與選單列，並停用 App 切換、
   Hide、Apple menu 與 Force Quit 面板。
3. local `NSEvent` monitor 接收送給 KeyClean 的鍵盤事件。
4. monitor 先辨識 `⌃⌥⌘U`，再對 key-down、key-up、修飾鍵與可見的
   system-defined event 回傳 `nil`。
5. 點擊 Unlock 或按快捷鍵後，移除 monitor、還原 presentation options、
   關閉所有遮罩並退出。

它只修改送給 KeyClean 自己的事件，因此不需要「輔助使用」或「輸入監控」。
這也是其界線：某些媒體鍵、Touch ID 或電源鍵可能在 App 可以取消前就由
macOS 處理。

Safe Mode 會監看螢幕配置變動並同步遮罩。如果 KeyClean 失去 App 焦點，
它會立即退出，而不是假裝仍能攔截已無法接收的事件。

## Full Lock event flow

1. `KeyCleanFull.app` 先以 `AXIsProcessTrusted()` 檢查。
2. 缺少權限時，一般視窗層級的面板會提供 Open System Settings 與
   Cancel。開啟「系統設定」時，面板會退到其後方，避免遮住權限控制項。
3. KeyClean 監聽 `NSApplication.didBecomeActiveNotification`；從「系統
   設定」回到 KeyClean 時會再次呼叫 `AXIsProcessTrusted()`，授權完成便
   自動開始 Full Lock。macOS 沒有提供此權限的公開 TCC-change callback。
4. 授權後，在 session event-tap chain 的前端建立使用
   `CGEventTapOptions.defaultTap` 的 active `CGEventTap`。
5. callback 對鍵盤、修飾鍵與可見 system-defined event 回傳 `nil`，並在
   丟棄前先辨識 `⌃⌥⌘U`。
6. 小型置頂面板仍可用滑鼠操作；解鎖時停用並 invalidate event tap、移除
   run-loop source、關閉面板並退出。

Event mask 刻意不包含 pointer event。若 macOS 因逾時而停用 event tap，
callback 會重新啟用；終止程序時 macOS 也會自動移除 tap。

## 為什麼兩種模式使用不同 App

Active event filter 能丟棄輸入，但需要 macOS「輔助使用」。Listen-only
event tap 可以使用較窄的「輸入監控」，卻不能實作 keyboard suppression。

「輔助使用」提供的 input capability 比 KeyClean 所需更廣；macOS 沒有
公開的「只允許攔截鍵盤」TCC capability。因此免費版把廣泛權限隔離到
`KeyCleanFull.app`，預設 Safe Mode app 與終端機都不會取得。

撤銷 KeyClean 的 Full Lock 決策、但不碰終端機權限：

```sh
keyclean --revoke-full-access
```

`keyclean --full-once` 會在 LaunchServices 啟動的 Full Lock app 結束後立即
執行同一組重設。由於 CLI 會持續等待，因此只要 CLI 本身仍在，Cancel 與
app crash 也包含在內。

任一 KeyClean app 執行期間，CLI 都會拒絕重設權限。它會重設目前的 Full
Lock identifier 與早期 v0.2 preview 使用的 KeyClean identifier，也會清掉
preview 的 `PostEvent` 決策，但永遠不會重設終端機的隱私設定。

## 簽章界線

Homebrew Formula 會在本機編譯不可變 tag 的原始碼。預設 split build 使用
ad-hoc code signature 與 Hardened Runtime 封裝組裝後的程式，但 ad-hoc
signature 沒有發布者身分，也沒有 notarization。

Split layout 是唯一支援的建置。兩個 app 都不帶 entitlement，也沒有網路
或檔案處理功能；但此建置沒有由作業系統強制執行「禁止網路」的界線。

## 復原方式

- 用觸控板／滑鼠點擊 **Unlock Keyboard**。
- 按下 `Control + Option + Command + U`。
- 從另一個 session 終止作用中的 KeyClean app。
- Safe Mode 若失去焦點，會自動還原狀態並退出。

無論 app crash 或被 kill，都不會留下 monitor 或 event tap，因為兩種機制
都隸屬於已終止的程序。
