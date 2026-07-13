《萌灵小岛》草丛区资源包 01

目录：
assets/world/tiles/grass/
- grassland_ground_01.png
- grassland_ground_02.png
- tall_grass_tile.png
- grass_path_edge.png

assets/world/props/grassland/
- tall_grass_cluster_a.png
- tall_grass_cluster_b.png
- bush_cluster_large.png
- wildflower_cluster.png
- grass_spirit_marker.png
- tree_small_a.png

previews/
- Tile 的 4×4 重复预览，便于检查拼接效果。

source_highres/
- 保留 AI 生成的高分辨率源图，方便后续手工精修。

说明：
1. 3 张纯地面 Tile 已处理为可平铺的 64×64 版本。
2. grass_path_edge.png 作为过渡地块，保留了方向性，因此采用缩放裁切到 64×64，而不是镜像拼接。
3. 独立物件已尝试移除浅色棋盘背景，并导出为透明 PNG。
4. 由于 AI 生成图本身不是严格生产级素材，建议接入 Godot 后继续人工检查透明边缘、碰撞轮廓和缩略显示效果。
5. tree_small_a.png 为普通可放置小树；大树树干/树冠分层资源不在本批次内。
