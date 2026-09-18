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

Fluent includes a compact global chat with player avatar (or two-letter initials), masked player name (first three characters plus `*****`), current game name, polling, and message sending. Names are masked when sent and when rendered, including for older messages returned by the API. `Example.luau` includes a **Global Chat** tab. Set `GLOBAL_CHAT_ENDPOINT` there to your deployed `/api/global-chat` URL.

For a floating chat button instead of a tab, use:

```lua
local Chat = Library:CreateGlobalChat({
    Endpoint = "https://your-domain.example/api/global-chat",
    ApiKey = "", -- same value as `GLOBAL_CHAT_API_KEY` in production
    PollInterval = 3,
    Open = true,
})
```

To embed the chat in a tab, pass `Parent = Tabs.GlobalChat.Container` and `Inline = true`. Inline chat fills the visible tab height, keeps the message composer pinned above the bottom edge, and uses larger touch targets on mobile. Client scripts are readable by players, so `ApiKey` is not a private secret; never place database credentials here.

The **Allow Join: OFF/ON** control in the chat header is off by default. When enabled on a public server, the client shares its current place ID and JobId with the relay while the chat is running. Other players see **Join Server** beside that player's messages and must confirm **Yes** or **No** before a teleport is attempted. Switching the control off removes the shared server immediately; stale shares expire after 60 seconds. The relay's startup migration creates `globalChatPresence` automatically, using the existing database and API key. Client-side teleports can still fail when a destination place restricts direct or third-party teleports, or when a server is full. The current shared-key protocol does not authenticate Roblox player IDs, so join status and role tags are display features, not trusted identity or access controls.

Every message has a `•••` action button. **Copy** sends its text to the executor clipboard when that API is available. **Reply** opens a cancellable reply bar above the composer; the relay stores a safe snapshot of the referenced message so the reply context is visible to every chat client. Existing databases receive the nullable reply columns automatically during startup migration.

In supported executors, Global Chat uses the executor's `request` function (including Real Executor) because client-side `HttpService:RequestAsync` can be disabled. You may also pass `Request = request` in the config to supply a transport explicitly. If no executor request function is available, it falls back to Roblox `HttpService:RequestAsync`.

The companion `discord-webhook-protector-codex-auth-redesign-preview` project exposes `/api/global-chat`, backed by its existing MySQL `DATABASE_URL`. Its startup migration creates `globalChatMessages`; the relay keeps the latest 200 messages across server restarts and instances. Set `GLOBAL_CHAT_API_KEY` in production and pass the same value as `ApiKey` above (the relay is intentionally disabled in production when the key is missing). Payloads are sanitized and a per-player send cooldown applies.

On Railway, the endpoint is the website service's public HTTPS domain followed by `/api/global-chat`. `GLOBAL_CHAT_API_KEY` is not generated by the app: create a random value in the website service's Variables tab and deploy that change. The current shared-key protocol requires the client to send this value, so it cannot be kept secret from people running the script. Do not use a database password or any other privileged key for it.
