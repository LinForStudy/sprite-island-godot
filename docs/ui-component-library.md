# 萌灵小岛 UI 组件库

## 目标

当前 UI 组件库不依赖 Figma，以 Godot 4.x 原生组件为准。清晰可读优先，避免把概念切图拉伸成正式皮肤。

## 基准

- 设计基准：1280×720
- 兼容：1920×1080、常见手机横屏比例
- 触控按钮最小点击区域：56×56
- 大面板内边距：20px 到 28px
- 圆角：12px 到 20px

## 主题资源

主 Theme：`res://resources/themes/cozy_theme.tres`

主题覆盖：

- `PanelContainer`
- `Button`：normal / hover / pressed / disabled
- `Label`
- `ProgressBar` 兼容旧控件
- `ScrollBar`
- `TooltipPanel`

## 推荐组件组合

### 大面板

使用：

- `PanelContainer`
- `MarginContainer`
- `VBoxContainer` / `HBoxContainer` / `GridContainer`
- `ScrollContainer`

禁止：

- `StyleBoxTexture`
- 自动裁切概念图作为背景
- 自动裁切概念图作为九宫格

### 普通按钮

使用：

- `Button`
- Theme 默认样式
- `custom_minimum_size` 高度不小于 48，主要触控按钮不小于 56

### 小图标

使用：

- `Button.icon`
- `TextureRect`

限制：

- 显示尺寸控制在 20px 到 36px
- 不得承担按钮、面板、HUD 的拉伸皮肤职责

### 战斗状态条

使用：

- `TextureProgressBar`
- 项目内生成的 Godot 资源纹理或后续正式 UI 条素材

当前战斗页已使用 `TextureProgressBar` 表示 HP 和能量。

## NinePatch 预留

目录：`res://assets/ui/ninepatch/`

后续仅允许放入正式制作的：

- `dialog_panel`
- `large_panel`
- `card_panel`
- `primary_button`

自动裁切概念图不允许移动到该目录伪装成正式 NinePatch。

## 已重构页面

- 顶部 HUD：`res://scenes/ui/gameplay_ui.tscn`
- 图鉴：`res://scenes/ui/gameplay_ui.tscn`
- 小屋：`res://scenes/ui/gameplay_ui.tscn`
- 战斗界面：`res://scenes/battle/battle_scene.tscn`
- 对话框：`res://scenes/ui/dialogue_ui.tscn`

## 验证

运行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1
```

检查脚本会阻止旧的糊图皮肤引用回归。

## Check markers

- FORBIDDEN_STRETCHED_CONCEPT_SKIN`n