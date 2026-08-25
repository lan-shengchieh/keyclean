# Share keyclean

Thank you for helping more Mac users discover `keyclean`. Adapt the copy to your
own voice, disclose that you are the maintainer when applicable, and follow each
community's current self-promotion rules.

## Facts and links

- Repository: <https://github.com/lan-shengchieh/keyclean>
- Latest release: <https://github.com/lan-shengchieh/keyclean/releases/latest>
- License: MIT
- Price: free
- Install: `brew install lan-shengchieh/tap/keyclean`
- Unlock: `Control + Option + Command + U`
- Data: no network code, analytics, background service, or stored input
- Landscape image: [GitHub social preview](.github/social-preview.jpg)
- Square image: [social launch card](.github/social-launch-square.jpg)

## Short English post

> I built keyclean, an open-source macOS keyboard-cleaning utility with two
> security modes. Safe Mode is the permission-free default; Full Lock is opt-in
> and grants Accessibility to a dedicated KeyClean app—not Terminal. Both keep
> the pointer available and exit after unlocking. No network code, analytics, or
> background service.
>
> `brew install lan-shengchieh/tap/keyclean`
>
> Feedback and compatibility reports are welcome:
> https://github.com/lan-shengchieh/keyclean

## 繁體中文短文

> 我做了 keyclean，一個有兩種安全模式的開源 macOS 鍵盤清潔工具。
> Safe Mode 預設完全不需權限；選用 Full Lock 時，「輔助使用」只授予
> KeyClean app，不授予 Terminal。兩種模式都保留游標，且沒有網路程式碼、
> 分析追蹤或背景常駐。
>
> `brew install lan-shengchieh/tap/keyclean`
>
> 歡迎提供 macOS、Mac 架構與終端機的相容性結果：
> https://github.com/lan-shengchieh/keyclean

## Show HN

**Title**

> Show HN: keyclean – lock Mac keyboard input while keeping the trackpad usable

**First comment**

> I wanted a keyboard-cleaning tool that did not require granting broad privacy
> access to Terminal. keyclean now defaults to a permission-free foreground
> overlay. Its optional Full Lock launches a separate app through LaunchServices
> and uses a session CGEventTap while deliberately excluding pointer events.
> Homebrew builds the tagged source directly, and both modes stop on ⌃⌥⌘U.
>
> The source and event-flow explanation are public. I would especially value
> reports from different macOS versions, Mac architectures, and terminal apps.

Read the current [Show HN guidelines](https://news.ycombinator.com/showhn.html)
before submitting and remain available to answer technical questions.

## r/macapps

Use the required open-source title prefix and current promotion format. At the
time this kit was prepared, the community also required sufficient subreddit
karma and limited developer self-promotion frequency; check the live rules first.

**Title**

> [OS] keyclean — permission-free Mac keyboard cleaning, with optional Full Lock

**Body**

> **Problem:** Cleaning a MacBook keyboard can trigger shortcuts and accidental
> typing.
>
> **Security model:** Safe Mode asks for no privacy permission. Optional Full
> Lock gives Accessibility to a separate, short-lived KeyClean app instead of
> Terminal. Both keep the pointer available and install no persistent service.
>
> **Pricing:** Free and open source (MIT) —
> https://github.com/lan-shengchieh/keyclean
>
> **Install:** `brew install lan-shengchieh/tap/keyclean`
>
> **Changelog:** https://github.com/lan-shengchieh/keyclean/releases/latest
>
> **AI disclosure:** Choose the community's truthful current label before posting
> and disclose that Codex assisted with development and launch preparation.

## Longer technical post

**Title**

> Building a permission-free macOS cleaning mode with an isolated CGEventTap fallback

**Outline**

1. Why closing or locking the Mac is inconvenient while cleaning a keyboard.
2. Why local AppKit event handling can provide a permission-free default.
3. Why complete system-wide suppression still needs an active `CGEventTap`.
4. How LaunchServices makes KeyClean, not Terminal, the responsible process.
5. Detecting the unlock chord and preserving pointer input.
6. Accessibility, ad-hoc signing, permission boundaries, and process-exit recovery.

Start from [the technical explanation](docs/how-keyclean-works.md), add personal
experience and original test results, and link back to the repository once.

## Tester invitation

> Would you be willing to spend two minutes testing an open-source Mac utility?
> Install with `brew install lan-shengchieh/tap/keyclean`, test permission-free
> Safe Mode and optional `keyclean --full`, then unlock with ⌃⌥⌘U. Please report
> the mode, macOS version, Apple Silicon/Intel, terminal app, and which app appears
> in Accessibility here:
> https://github.com/lan-shengchieh/keyclean/issues/new?template=compatibility_report.yml

Ask for testing and honest feedback, not stars. Never send unsolicited bulk
messages or ask people to manipulate votes.

## Curated-list submission entry

> [keyclean](https://github.com/lan-shengchieh/keyclean) — Permission-free Mac
> keyboard cleaning by default, with an optional isolated Full Lock that keeps
> the trackpad and mouse available. Free, open source, and installable through
> Homebrew.

Potential lists include maintained macOS and CLI collections. Submit to one
relevant category at a time, follow its contribution format exactly, and avoid
opening duplicate submissions across many low-quality lists.
