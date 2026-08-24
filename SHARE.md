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
- Data: no network access, analytics, background service, or stored input
- Landscape image: [GitHub social preview](.github/social-preview.jpg)
- Square image: [social launch card](.github/social-launch-square.jpg)

## Short English post

> I built keyclean, a tiny open-source macOS CLI for cleaning a MacBook keyboard
> without accidental input. It blocks keys while keeping the trackpad available,
> then exits with ⌃⌥⌘U. One Swift file, no dependencies, network access,
> analytics, or background service.
>
> `brew install lan-shengchieh/tap/keyclean`
>
> Feedback and compatibility reports are welcome:
> https://github.com/lan-shengchieh/keyclean

## 繁體中文短文

> 我做了 keyclean，一個清潔 MacBook 時暫時鎖住鍵盤、但保留觸控板的
> 開源 macOS CLI。按 ⌃⌥⌘U 就能解鎖；只有一個 Swift 原始碼檔，不連網、
> 不蒐集資料，也不常駐背景。
>
> `brew install lan-shengchieh/tap/keyclean`
>
> 歡迎提供 macOS、Mac 架構與終端機的相容性結果：
> https://github.com/lan-shengchieh/keyclean

## Show HN

**Title**

> Show HN: keyclean – lock Mac keyboard input while keeping the trackpad usable

**First comment**

> I wanted a keyboard-cleaning tool that I could launch from Terminal without
> installing a menu-bar app or background helper. keyclean is one Swift file. It
> creates a session CGEventTap for keyboard events, deliberately excludes pointer
> events, and stops on ⌃⌥⌘U. Homebrew builds the tagged source directly.
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

> [OS] keyclean — a free one-file CLI that locks Mac keys but keeps the trackpad usable

**Body**

> **Problem:** Cleaning a MacBook keyboard can trigger shortcuts and accidental
> typing.
>
> **Comparison:** Full cleaning-mode apps often lock pointer input or add a
> persistent menu-bar app. keyclean is intentionally narrower: run it from
> Terminal, keep the trackpad available, and audit the entire implementation in
> one Swift file.
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

> Building a one-file macOS keyboard lock with CGEventTap

**Outline**

1. Why closing or locking the Mac is inconvenient while cleaning a keyboard.
2. Why `CGEventTap` is enough and a kernel extension is unnecessary.
3. How excluding pointer events keeps the trackpad available.
4. Detecting the unlock chord before swallowing the event.
5. Accessibility permission and safe recovery when the process exits.
6. The privacy benefit of one auditable source file and no network path.

Start from [the technical explanation](docs/how-keyclean-works.md), add personal
experience and original test results, and link back to the repository once.

## Tester invitation

> Would you be willing to spend two minutes testing an open-source Mac utility?
> Install with `brew install lan-shengchieh/tap/keyclean`, run `keyclean`, confirm
> that keys are blocked while the pointer still moves, then unlock with ⌃⌥⌘U.
> Please report your macOS version, Apple Silicon/Intel, and terminal app here:
> https://github.com/lan-shengchieh/keyclean/issues/new?template=compatibility_report.yml

Ask for testing and honest feedback, not stars. Never send unsolicited bulk
messages or ask people to manipulate votes.

## Curated-list submission entry

> [keyclean](https://github.com/lan-shengchieh/keyclean) — Temporarily lock macOS
> keyboard input from Terminal while keeping the trackpad and mouse available.
> Free, open source, and installable through Homebrew.

Potential lists include maintained macOS and CLI collections. Submit to one
relevant category at a time, follow its contribution format exactly, and avoid
opening duplicate submissions across many low-quality lists.
