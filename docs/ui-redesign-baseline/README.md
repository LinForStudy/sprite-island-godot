# UI 改造截图验收规范

本目录保存 UI 改造前后的可比较截图。现有 `*-before-1280x720.png` 文件是 P0 基线；后续阶段一律遵循以下规则。

## 文件命名

使用小写 ASCII 文件名：

```text
p{阶段}-ui{任务号}-{页面}-{状态}-1280x720.png
```

示例：

```text
p1-ui101-modal-shell-default-1280x720.png
p2-ui202-world-hud-default-1280x720.png
p3-ui305-dex-selected-1280x720.png
p4-ui407-home-empty-1280x720.png
```

- `{阶段}`：路线图阶段编号，例如 `1`、`2`。
- `{任务号}`：去掉连字符的任务编号，例如 `101`、`305`。
- `{页面}`：`modal-shell`、`world-hud`、`dex`、`home`、`habitat`、`encounter` 或 `battle-prep`。
- `{状态}`：`default`、`selected`、`empty`、`disabled`、`closed` 或任务验收所需的明确状态。

同一任务至少保留一个 `default` 截图；涉及选择、空态、禁用、关闭或返回的任务，额外各保留一个对应状态截图。

## 1280×720 验收流程

1. 用 Godot 4.x 运行 `scenes/world/test_world.tscn`，将窗口设为 1280×720 横屏；不缩放系统显示、不裁切截图。
2. 从稳定的初始存档或清晰复现步骤进入目标页面，确认目标任务之外的玩法、存档字段和数据接口未被修改。
3. 检查文字可读、主要焦点明确、最小可点按控件不小于 56×56px；页面打开时保留世界背景时，还需确认遮罩和关键地图入口可辨识。
4. 截取默认状态；按任务范围再截取选中、空态、禁用或操作后的反馈状态。
5. 对带弹窗的页面，用右上关闭、`Esc` 或返回输入关闭一次，确认回到原世界状态且未发生非预期写入；需要时保存 `closed` 截图。
6. 将截图存入本目录，按本规范命名；在路线图对应任务状态中记录实际文件路径。
7. 运行 `powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1`，通过后才将任务标记为完成。

## 最小证据清单

| 任务类型 | 必需截图 |
| --- | --- |
| 新组件 | `default` |
| HUD 调整 | `default`，并确认关键地图区域可见 |
| 图鉴/小屋 | `default` + `selected`；有空态/禁用条件时增加对应截图 |
| 弹窗/返回行为 | `default` + `closed` |
| 有数值操作反馈 | `default` + 操作后状态 |