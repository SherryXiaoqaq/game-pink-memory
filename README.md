# Pink Memory ♡

> **把每次见面，玩成一次心动闯关。**

Pink Memory 是一个为情侣设计的手机端回忆小游戏。  
它把真实照片、见面时间和小游戏结合起来：玩家通过拼图、找不同、快速记忆、管道连通等关卡，逐步解锁属于两个人的照片，最终组成按时间排列的专属回忆册。

<p align="center">
  <img src="assets/poster.png" width="720" alt="Pink Memory Poster">
</p>

## ✨ 项目特色

- 💗 **自定义回忆关卡**：添加日期、地点、照片和简短备注
- 🎮 **多种小游戏**：照片碎片拼图、追爱心、翻牌、管道连通、快速记忆、找不同、照片换位、照片迷宫
- 📷 **通关解锁照片**：每一关对应一段真实见面回忆
- 📖 **时间线照片书**：已解锁照片自动按日期整理
- 👩‍❤️‍👨 **双人共享纪念册**：两个人进入同一套回忆内容
- 🏆 **独立通关进度**：双方拥有各自的游戏完成记录
- 📱 **Mobile First**：为手机浏览器操作设计

## 🎮 游戏玩法

| 游戏 | 玩法 |
|---|---|
| 照片碎片拼图 | 拖动 20 / 30 块拼图恢复完整照片 |
| 追爱心 | 在限时内追踪不同大小、位置和分值的爱心 |
| 照片翻牌 | 记住照片局部并完成配对 |
| 管道连通 | 旋转管道，把入口真正连接到出口 |
| 快速记忆 | 记忆照片区域的闪烁顺序并依次点击 |
| 照片找不同 | 找到照片中经过处理的局部变化 |
| 照片换位 | 交换照片块并恢复原图 |
| 照片迷宫 | 在照片背景中完成迷宫挑战 |

## 💡 核心概念

一次见面 = 一段回忆 = 一个小游戏关卡。

用户可以为每次见面上传照片并选择对应玩法。完成关卡后照片被解锁，所有回忆最终汇总成一册完整的时间线相册。

> **见面一次，解锁一关。**

## 🛠 技术栈

- HTML / CSS / JavaScript
- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- Row Level Security (RLS)
- Netlify

## 📁 项目结构

```text
pink-memory/
├── index.html
├── config.example.js
├── setup_supabase.sql
├── .gitignore
├── README.md
└── assets/
    └── poster.png
```

## 🚀 本地配置

### 1. 创建 Supabase 项目

创建一个 Supabase 项目，并在 SQL Editor 中运行：

```text
setup_supabase.sql
```

### 2. 创建照片 Bucket

在 Supabase Storage 中创建一个 Private bucket：

```text
memory-photos
```

### 3. 配置前端

复制：

```text
config.example.js
```

并重命名为：

```text
config.js
```

填入自己的 Supabase Project URL 和 Publishable Key：

```js
window.PINK_MEMORY_CLOUD = {
  url: "https://YOUR_PROJECT.supabase.co",
  publishableKey: "YOUR_SUPABASE_PUBLISHABLE_KEY"
};
```

### 4. 打开 / 部署

可以使用静态网站托管服务部署，例如 Netlify。

## 🔐 隐私说明

本仓库只包含项目代码和展示素材，不包含实际情侣照片、账号密码或线上数据库内容。

请不要在公开仓库中提交：

- Supabase Secret Key
- `service_role` Key
- 用户密码
- 不希望公开的私人照片

## 📸 Preview

> 这里可以继续添加游戏首页、关卡选择、拼图、照片书等截图。

## 🌷 Slogan

**把每次见面，玩成一次心动闯关。**

**你们的故事，不止收藏，更值得一起玩。**

---

Made with ♡ for shared memories.
