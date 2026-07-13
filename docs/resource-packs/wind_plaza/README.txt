《萌灵小岛》迎风广场美术资源包 01

目录：
assets/world/tiles/grass/
- grass_base_01.png
- grass_base_02.png
- grass_base_03.png

assets/world/tiles/road/
- plaza_ground.png
- road_base.png

assets/world/props/plaza/
- plaza_signpost.png
- small_bush_a.png
- small_bush_b.png
- flower_patch_a.png
- stone_small_a.png

previews/
- 5 张 Tile 的 4×4 重复预览，便于检查拼接。

source_highres/
- 保留 AI 生成的高分辨率原图，方便后续人工精修。

说明：
1. Tile 已处理为 64×64，并使用镜像象限方法保证四边能够连续拼接。
2. 镜像无缝会带来一定对称感，适合当前原型；正式版本建议由美术人工重绘边缘和变化 Tile。
3. 独立物件已尝试移除生成图中的棋盘格背景，并导出透明 PNG。
4. AI 生成的透明边缘可能仍有少量浅色残留，建议接入 Godot 后在深色背景上复查。
5. Godot 导入像素过滤建议：
   - 非像素手绘风素材保持 Filter 开启；
   - 不启用 Nearest；
   - 物件通过 Sprite2D 使用；
   - 地面 Tile 通过 TileSet Atlas Source 使用。
