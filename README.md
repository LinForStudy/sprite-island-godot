# 萌灵小岛：Godot 原型

《萌灵小岛》是一个 Godot 4.x 单机中文怪物收集 RPG 原型。

## 当前可玩内容

- 两张探索地图：新手岛与林间入口；六个按进度单向解锁的栖息地。
- 首次与迎风向导交谈会一次性获得叶团团与初始物资。
- 发现、战斗、收服、小屋照料、图鉴、队伍与背包均使用本地 JSON 存档，并提供备份恢复。
- 出战队伍最多 3 只：在主菜单的“队伍”页可从已入住萌灵中加入或移出；战斗准备只允许选择队伍成员。
- 六个独立战斗场景、站位选择门禁、战后收服与云台首次收服后的原型完成总结。
- 桌面键鼠与手机横屏触控；图鉴、小屋、对话、战斗和主菜单均接入响应式布局。
- 本地设置：主音量、音乐、音效、全屏/窗口；世界与战斗音乐、移动、技能、受击和成功收服音效已接入。

## 运行

1. 使用 Godot 4.x 打开 `project.godot`。
2. 运行主场景 `res://scenes/world/test_world.tscn`。
3. 新档路径：与向导交谈 → 草丛收服 → 池塘 → 暖石 → 林间入口 → 风车 → 山洞 → 云台。

## 操作

- `WASD` / 方向键：移动。
- `E` / `Space` / `Enter`：交互、推进对话、确认。
- `Esc`：打开或关闭主菜单。
- 手机横屏：虚拟摇杆、交互、确认、返回和菜单按钮。

## 自动检查

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1

# 统一运行时回归：世界/输入/存档/UI/设置音频/战斗 smoke
powershell -ExecutionPolicy Bypass -File scripts/run-regression.ps1
```

还可运行：

```powershell
# 存档迁移、首宠、解锁、队伍与背包规则
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/verify_save_v2.gd

# 五种分辨率 UI 结构检查
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/verify_ui_matrix.gd

# 六战场与战斗帧资源合同
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64_console.exe' --headless --path . res://scenes/battle/battle_contract_smoke.tscn

# 设置独立存档、音频总线与资源检查
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64_console.exe' --headless --path . res://scenes/testing/settings_audio_smoke.tscn

# 数值、收服经济和属性克制合同
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/verify_gameplay_balance.gd
```

## 当前封版缺口

正式 M6 封版仍需补齐剩余 8 只萌灵的战斗动画资源，并完成最终人工全流程验收。当前工作优先保持既有存档、地图、战斗与收服逻辑稳定。