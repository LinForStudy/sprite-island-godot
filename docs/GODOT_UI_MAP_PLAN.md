# 《萌灵小岛》Godot UI 与地图组件接入计划

## 1. 先区分两类资源

### A. UI 图片资源
适合直接放入 `assets/ui/`：
- HUD 装饰
- 导航按钮
- 圆角面板
- 对话框边框
- 属性与状态图标
- 萌灵头像框
- 战斗技能按钮

### B. 地图资源
不要把设计稿中的整张岛屿截图直接当作可行走地图。
地图应重新拆为：
- `TileSet`：草地、道路、水、沙滩、悬崖、桥梁
- `Scene`：树、房屋、风车、路牌、探索点、洞穴入口
- `Decoration`：花、石头、灌木、木桩
- `Collision`：水域、墙体、树干、建筑
- `NavigationRegion2D`：NPC 或萌灵寻路区域

## 2. 推荐项目目录

```text
assets/
  ui/
    panels/
    buttons/
    icons/
    portraits/
    hud/
  world/
    tilesets/
    props/
    buildings/
    decorations/
scenes/
  ui/
    hud.tscn
    bestiary_panel.tscn
    home_panel.tscn
    inventory_panel.tscn
    battle_ui.tscn
  world/
    props/
    buildings/
resources/
  themes/
    cozy_theme.tres
  tilesets/
    island_tileset.tres
```

## 3. UI 的 Godot 实现方式

- 外层页面：`Control`
- 响应式布局：`MarginContainer + VBoxContainer + HBoxContainer`
- 弹窗：`PanelContainer`
- 可拉伸边框：`NinePatchRect`
- 普通按钮：`Button` + `Theme`
- 图标按钮：`TextureButton`
- 头像：`TextureRect`
- 血条、经验条：`TextureProgressBar`
- 图鉴列表：`ScrollContainer + VBoxContainer`
- 背包网格：`GridContainer`
- 标签页：`TabContainer` 或自定义按钮组
- 全局 UI 风格：统一写入 `cozy_theme.tres`

不要通过大量绝对坐标摆放 UI。横屏基准建议 1280×720，并通过容器适配 16:9、18:9 和电脑窗口。

## 4. 九宫格配置

对于 `panel_large.png`、`dialog_left.png` 等边框资源：
1. 使用 `NinePatchRect`
2. 在 Inspector 中设置 Patch Margin
3. 建议先试：Left/Right 18，Top/Bottom 18
4. Draw Center 保持开启
5. UI 文本和按钮作为其子节点放置

当前切图来自概念设计稿，边缘不一定完全对称。正式接入前应在 Godot 中逐张检查拉伸效果。

## 5. 地图重建方案

### TileMapLayer 分层
Godot 4.x 建议：
- `GroundLayer`：草地、泥土、道路、沙滩
- `WaterLayer`：海水、池塘、河流
- `CliffLayer`：高低差和岸边
- `DecorationLayer`：花草和碎石
- `CollisionLayer`：不可通行区域
- `ForegroundLayer`：树冠、屋顶等遮挡玩家的内容

### 独立场景组件
以下不要做进单一 TileSet：
- 房屋
- 风车
- 大树
- 洞穴入口
- 探索点
- NPC
- 桥梁（复杂桥梁）
- 传送门

每个组件做成独立 `.tscn`：
```text
Node2D
├─ Sprite2D
├─ StaticBody2D
│  └─ CollisionPolygon2D
├─ Marker2D
└─ Area2D
```

### Y 排序
世界根节点启用 Y Sort，或将角色、NPC、树干、建筑放入启用 Y Sort 的同一节点。树冠与屋顶单独放在前景层。

## 6. 建议实施顺序

1. 建立 `cozy_theme.tres`
2. 重做顶部 HUD
3. 重做图鉴弹窗
4. 重做小屋界面
5. 重做战斗 HUD
6. 重做背包与任务界面
7. 建立地图 TileSet 分层
8. 把房屋、风车、树、探索点拆为场景
9. 添加碰撞与 Y 排序
10. 运行 `scripts/check-project.ps1`

## 7. 重要限制

本包来自一张完整设计稿的自动切图，不是 PSD/Figma 分层源文件：
- 可用于 UI 原型验证
- 不保证所有透明边缘完全干净
- 不保证九宫格无拉伸瑕疵
- 不适合直接用作正式 TileSet
- 地图截图只能作为视觉参考，不能直接作为 TileMap 素材
