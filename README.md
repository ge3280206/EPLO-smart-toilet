# EPLO Smart for iOS（iPhone 版）— 如何变成能装的 IPA

工程已完成，与安卓版功能一致：SwiftUI + CoreBluetooth 蓝牙 + Wi-Fi TCP，52 项功能、全英文界面、#005670 主题、官方 LOGO 图标，版本 5.2.2。

## 唯一的客观限制

苹果的 iOS 应用只能用 macOS 上的 Xcode 编译。**Windows 上没有任何办法直接生成 .ipa**。
所以下面给出三条路，都能拿到可安装的 APP，选一条即可。

---

## 路线 A：GitHub 云端自动打包（不需要 Mac，全程 Windows 可完成）★推荐

1. 注册/登录 GitHub（免费）：https://github.com
2. 新建一个仓库（Private 也可以），把这个文件夹里的 `EPLOiOS/` 和 `.github/` **一起上传**（网页拖拽即可）
3. 进仓库 → **Actions** 标签 → 左侧 **Build iOS IPA** → 右侧 **Run workflow** → 绿色按钮
4. 等 3～5 分钟，点进这次运行 → 页面底部 **Artifacts** → 下载 `EPLOSmart-unsigned-ipa`
5. 解压得到 `EPLOSmart-unsigned.ipa`
6. 在 Windows 装 **Sideloadly**（https://sideloadly.io），手机连电脑：
   - 把 ipa 拖进去，填你的 Apple ID，点 Start
   - iPhone 上：设置 → 通用 → VPN与设备管理 → 信任你的开发者证书
   - 完成，桌面上就有 EPLO Smart 图标了

> 免费 Apple ID 签的 App **7 天有效期**，到期用 Sideloadly 重新签一次即可（1 分钟）。
> 想长期不过期：Apple 开发者账号 $99/年，或改用 AltStore 自动续签。

---

## 路线 B：手上有 Mac（最快最稳）

1. 把 `EPLOiOS` 文件夹拷到 Mac
2. 终端执行：`chmod +x build_ipa.sh && ./build_ipa.sh`
3. 得到 `EPLOSmart-unsigned.ipa`，同样用 Sideloadly 装；或者直接 Xcode 打开工程点 ▶ 装到自己手机

---

## 路线 C：要正式发给客户 / 上架（需要 $99 开发者账号）

1. Xcode 打开 `EPLOiOS.xcodeproj`，Signing 里选你的 Team
2. Product → Archive → Distribute App
3. 选 **TestFlight**（客户扫码安装，90 天有效，推荐）或 **Ad Hoc**（指定设备直装，不上架也能用）
4. 需要我把它上架 App Store 的话，还需要：App 名称、隐私政策链接、截图、应用描述

---

## 首次运行权限

- 蓝牙权限：必须允许（否则扫不到马桶）
- 本地网络权限：Wi-Fi 连接时弹出，必须允许
- 两个权限的说明文案已写进 `Info.plist`

## 协议说明

与安卓版完全同协议：`AA 55 | CMD | LEN | PAYLOAD | CRC8(MAXIM)`。
模组厂家给到正式协议后，iOS 侧只改 `Protocol.swift` 和 `Models.swift` 两处（命令码 / UUID），界面不用动。
