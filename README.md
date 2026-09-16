# Fluent Renewed

![Fluent Renewed Title](Assets/darkmode.png#gh-dark-mode-only)
![Fluent Renewed Title](Assets/darkmode.png#gh-light-mode-only)

## ⚡ Features

- Modern design
- Many customization options
- Almost any UI Element you would ever need

## 🔌 Installation

You can load Fluent through a GitHub Release:

```lua
local Library = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true))()
```

```lua
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true))()
```

## 📜 Usage

[Example Script the studio environment](https://github.com/ActualMasterOogway/Fluent-Renewed/blob/master/Example.client.luau)

[Example Script for an exploit environment](https://github.com/ActualMasterOogway/Fluent-Renewed/blob/master/Example.luau)

## Credits

- [Master Oogway](https://github.com/ActualMasterOogway/Fluent-Renewed) - The master mind behind Fluent Renewed
- [dawid](https://github.com/dawid-scripts/Fluent) - The master mind behind Fluent
- [Lucide](https://github.com/lucide-icons), [Phosphor](https://github.com/phosphor-icons) - The sexy icons
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy) - Assets for the UI, some of the code
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) - Code for most of the elements, save manager
- [7kayoh/Acrylic](https://github.com/7kayoh/Acrylic) - Porting richie0866's acrylic module to lua
- [Latte Softworks & Kotera](https://github.com/latte-soft/wax/) - Bundler
- [Pepsied-5229/Pepsi-UI-Library](https://github.com/Pepsied-5229/Pepsi-UI-Library) - Inspiration for new features, some of the code

## Compact mobile layout

Touch devices without a hardware keyboard automatically use a narrower sidebar, 26 px tabs, tighter cards and section spacing, and hide the workspace heading. Desktop spacing is unchanged. Density values live in `Src/Modules/Layout.luau`.

The root `Fluent.luau` in this revision includes the current source changes. Future source edits still need a fresh bundle; the repository build workflow uploads an artifact but does not automatically replace the root file.

## Global chat

Fluent includes a compact global chat with player avatar (or two-letter initials), player name, current game name, polling, and message sending. `Example.luau` includes a **Global Chat** tab. Set `GLOBAL_CHAT_ENDPOINT` there to your deployed `/api/global-chat` URL.

For a floating chat button instead of a tab, use:

```lua
local Chat = Library:CreateGlobalChat({
    Endpoint = "https://your-domain.example/api/global-chat",
    ApiKey = "", -- same value as `GLOBAL_CHAT_API_KEY` in production
    PollInterval = 3,
    Open = true,
})
```

To embed the chat in a tab, pass `Parent = Tabs.GlobalChat.Container` and `Inline = true`. Client scripts are readable by players, so `ApiKey` is not a private secret; never place database credentials here.

The companion `discord-webhook-protector-codex-auth-redesign-preview` project exposes `/api/global-chat`, backed by its existing MySQL `DATABASE_URL`. Its startup migration creates `globalChatMessages`; the relay keeps the latest 200 messages across server restarts and instances. Set `GLOBAL_CHAT_API_KEY` in production and pass the same value as `ApiKey` above (the relay is intentionally disabled in production when the key is missing). Payloads are sanitized and a per-player send cooldown applies.
