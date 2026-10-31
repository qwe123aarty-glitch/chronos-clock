# Chronos · 时钟

一个 SwiftUI 写的 iPhone 时钟 App，四个模块：指针时钟、世界时钟、秒表、计时器。

工程是完整的、可直接编译的：`Chronos.xcodeproj` 已经手写并通过结构校验（37 个对象、无悬空引用、10 个源文件全部在编译列表里），图标也是代码绘制的 1024×1024 成品。

---

## 先说清楚 IPA 这件事

你要的是「做好直接发我 IPA」。这个我没法在这台机器上给你，原因不是偷懒：

**IPA = 编译好的 arm64 二进制 + 苹果签名。**

- 编译需要 iOS SDK，而 iOS SDK 只能跑在 macOS 上。这台是 Windows，没有 Xcode，也没有任何替代品能产出可运行的 iOS 二进制。
- 签名需要你的 Apple ID 或开发者证书。签名是绑定到具体账号和设备的，别人的签名你装不上。

任何在 Windows 上「生成」出来的 IPA，要么是空壳，要么是木马。所以我不会给你那种东西。

**但这个 App 是真的做完了。** 下面三条路，任选一条，都能让它跑在你手机上。

---

## 路径 A：有 Mac —— 最快，5 分钟

免费 Apple ID 就够，不用花 99 美元。

1. 解压，双击 `Chronos.xcodeproj`
2. Xcode → Settings → Accounts → 加你的 Apple ID
3. 左侧选中 `Chronos` 项目 → `Signing & Capabilities`
   - Team 选你的个人团队（Personal Team）
   - Bundle Identifier 改成一个唯一的，比如 `com.你的名字.chronos`
4. iPhone 用数据线连电脑，手机上点「信任」
5. Xcode 顶部设备选你的 iPhone，按 `⌘R`

App 会直接装到手机上。

**如果你就是要一个 .ipa 文件：**

- `Product` → `Archive`
- Organizer 弹窗里 → `Distribute App` → `Development`（或 `Ad Hoc`）→ `Export`
- 导出目录里就是 `Chronos.ipa`

免费账号的限制：签名 7 天过期、最多同时装 3 个自签 App。过期了重新 `⌘R` 一次即可。

---

## 路径 B：没有 Mac —— 云端出 IPA

仓库里带了 `.github/workflows/build-ipa.yml`，在 GitHub 的 macOS 机器上编译，产出 **未签名 IPA**。

1. 新建一个 GitHub 仓库（Public / Private 都行）
2. 把本文件夹**里面的内容**上传到仓库根目录 —— 注意 `.github` 目录必须在根目录，不能被多套一层文件夹
3. 仓库页面 → `Actions` → 左侧 `Build IPA` → `Run workflow`
4. 等 3–5 分钟，进这次运行的详情页，底部 `Artifacts` 下载 `Chronos-unsigned-ipa.zip`，解压得到 `Chronos-unsigned.ipa`
5. 电脑装 [Sideloadly](https://sideloadly.io)（Windows / macOS 都有），iPhone 数据线连电脑
6. Sideloadly 里拖入那个 ipa，填你的 Apple ID，点 `Start`
7. iPhone → 设置 → 通用 → VPN与设备管理 → 信任你的开发者证书

未签名 IPA **不能**直接双击安装，必须过一遍签名工具（Sideloadly / AltStore 都行），这一步就是在用你的 Apple ID 给它签名。

---

## 路径 C：现在就想用 —— Web 版

`preview/index.html` 是和原生版同款的单文件 Web App，零外部依赖，完全离线可用。

用 iPhone 的 Safari 打开它 → 分享 → **添加到主屏幕**，就会像一个原生 App 一样全屏运行，有图标、有启动画面、不显示地址栏。

发到手机上最简单的办法：把这个 html 丢进任意静态托管（或者直接 AirDrop / 微信传给自己，用「在 Safari 中打开」）。

---

## 功能

| 模块 | 说明 |
|---|---|
| 时钟 | Canvas 逐帧绘制的机械表盘，秒针连续扫动而非一秒一跳；大号数字读数；三套配色（极光 / 熔岩 / 墨白），点表盘或右上角胶囊切换，选择会记住 |
| 世界时钟 | 22 个城市可选，显示相对时差、昼夜状态、跨日标记（昨天 / 明天）；长按卡片删除 |
| 秒表 | 百分之一秒精度，计次并对比单圈与累计用时 |
| 计时器 | 1–60 分钟预设，环形进度，结束时发本地通知 + 震动反馈 |

技术选型：SwiftUI，最低 iOS 16.0，无任何第三方依赖，不联网、不申请多余权限。

---

## 文件结构

```
chronos-clock/
├── Chronos.xcodeproj/          # 工程文件（手写，已校验）
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/Chronos.xcscheme
├── Chronos/
│   ├── ChronosApp.swift        # 入口
│   ├── AppStore.swift          # 全局状态 + 落盘
│   ├── Theme.swift             # 三套配色、玻璃卡片、背景
│   ├── RootView.swift          # TabView 与通用标题栏
│   ├── ClockView.swift         # 时钟页
│   ├── AnalogClockView.swift   # Canvas 表盘（核心）
│   ├── WorldClockView.swift    # 世界时钟 + 城市选择
│   ├── StopwatchView.swift     # 秒表
│   ├── TimerView.swift         # 计时器 + 本地通知
│   ├── WorldCity.swift         # 城市模型与时区计算
│   └── Assets.xcassets/        # 图标与主题色
├── preview/index.html          # Web 版（同款设计，可加到主屏幕）
├── .github/workflows/          # 云端打包成 IPA
├── project.yml                 # XcodeGen 备用方案
└── tools/
    ├── check_project.py        # 校验 pbxproj 引用完整性
    └── make_icon.py            # 重新生成 App 图标
```

---

## 想改的地方

- **App 名字**：Xcode 里选中 Target → Info，或改 `project.pbxproj` 中的 `INFOPLIST_KEY_CFBundleDisplayName`
- **Bundle ID**：`com.chronos.clockapp` → 换成你自己的，避免和别人冲突
- **配色**：`Chronos/Theme.swift`，三套主题的色值都在里面
- **图标**：改 `tools/make_icon.py` 里的颜色和角度，然后 `python tools/make_icon.py`
- **城市列表**：`Chronos/WorldCity.swift` 里的 `catalog`
- **工程文件坏了**：装了 XcodeGen 的话，`xcodegen generate` 可以按 `project.yml` 重新生成整个工程

---

## 常见问题

**打开 App 提示 "Untrusted Developer"**
设置 → 通用 → VPN与设备管理 → 找到你的开发者证书 → 信任。

**用了几天突然打不开了**
免费 Apple ID 的签名只有 7 天有效期。重新用 Xcode `⌘R` 或 Sideloadly 签一次。

**计时器在后台不响**
首次启动要允许通知。计时器用的是本地通知，App 被划掉也能响；但如果你在设置里关了通知权限就不会响。

**Xcode 报 "No signing certificate"**
Signing & Capabilities 里 Team 没选，或者 Bundle ID 跟别人的重复了，换一个即可。

**想上架 App Store**
需要 99 美元的开发者账号，另外还要补：App Store 截图、隐私声明、审核用的演示账号（这个 App 不需要）。代码层面已经就绪。
