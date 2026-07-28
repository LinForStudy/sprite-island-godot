$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$required = @(
  'project.godot',
  'icon.svg',
  'README.md',
  'AGENTS.md',
  'docs/phase-1-notes.md',
  'docs/mobile_landscape_roadmap.md',
  'docs/testing_matrix.md',
  'docs/GODOT_UI_MAP_PLAN.md',
  'docs/ui-kit-integration-report.md',
  'docs/ui-component-library.md',
  'docs/game-ui-redesign-roadmap.md',
  'docs/ui-redesign-baseline/world-hud-before-1280x720.png',
  'docs/ui-redesign-baseline/dex-before-1280x720.png',
  'docs/ui-redesign-baseline/home-before-1280x720.png',
  'docs/ui-redesign-baseline/README.md',
  'tilesets/world_tiles.tres',
  'data/catalog/habitats_phase1.json',
  'data/catalog/spirits_phase1.json',
  'scenes/player/player.tscn',
  'scenes/ui/dialogue_ui.tscn',
  'scenes/ui/gameplay_ui.tscn',
  'scenes/ui/components/game_modal_shell.tscn',
  'scripts/ui/components/game_modal_shell.gd',
  'scenes/ui/components/game_close_button.tscn',
  'scripts/ui/components/game_close_button.gd',
  'scenes/ui/components/filter_chip.tscn',
  'scripts/ui/components/filter_chip.gd',
  'scenes/ui/components/element_badge.tscn',
  'scripts/ui/components/element_badge.gd',
  'resources/themes/ui/modal_shell_panel.tres',
  'scenes/ui/components/stat_meter.tscn',
  'scripts/ui/components/stat_meter.gd',
  'scenes/ui/components/icon_action_button.tscn',
  'scenes/ui/ui_component_showcase.tscn',
  'scripts/ui/components/icon_action_button.gd',
  'scenes/ui/components/spirit_portrait_card.tscn',
  'scripts/ui/components/spirit_portrait_card.gd',
  'scenes/battle/battle_scene.tscn',
  'scenes/world/habitat_point.tscn',
  'scenes/world/test_npc.tscn',
  'scenes/world/scene_exit.tscn',
  'scenes/world/test_world.tscn',
  'scenes/world/grove_gate.tscn',
  'scripts/core/WorldState.gd',
  'scripts/core/game_catalog.gd',
  'scripts/verify_phase1_rules.gd',
  'scripts/player/player.gd',
  'scripts/camera/camera_controller.gd',
  'scripts/ui/DialogueUI.gd',
  'scripts/ui/gameplay_ui.gd',
  'scripts/ui/battle_scene.gd',
  'scripts/battle/battle_actor.gd',
  'scripts/battle/battle_action_result.gd',
  'scripts/battle/battlefield.gd',
  'scripts/battle/battle_presentation.gd',
  'scenes/battle/battle_actor.tscn',
  'scenes/battle/fields/battlefield_grassland.tscn',
  'scenes/battle/fields/battlefield_pond.tscn',
  'scenes/battle/fields/battlefield_warmstone.tscn',
  'scenes/battle/fields/battlefield_forest.tscn',
  'scenes/battle/fields/battlefield_cave.tscn',
  'scenes/battle/fields/battlefield_cloud.tscn',
  'scripts/world/TestNpc.gd',
  'scripts/world/habitat_point.gd',
  'scripts/world/scene_exit.gd',
  'scripts/world/world_scene.gd',
  'autoload/display_manager.gd',
  'autoload/save_manager.gd',
  'autoload/game_state.gd',
  'autoload/battle_manager.gd',
  'resources/device_profile.gd',
  'resources/desktop_profile.tres',
  'resources/mobile_landscape_profile.tres',
  'resources/spirit_skill.gd',
  'resources/spirit_data.gd',
  'resources/habitat_data.gd',
  'resources/themes/cozy_theme.tres',
  'assets/fonts/NotoSansSC-VF.ttf',
  'assets/placeholder/world/world_tiles.png',
  'assets/placeholder/world/npc_keeper.png',
  'assets/placeholder/ui/dialog_panel.png',
  'assets/placeholder/player/idle_down.png',
  'assets/placeholder/player/walk_down.png',
  'assets/placeholder/player/idle_up.png',
  'assets/placeholder/player/walk_up.png',
  'assets/placeholder/player/idle_left.png',
  'assets/placeholder/player/walk_left.png',
  'assets/placeholder/player/idle_right.png',
  'assets/placeholder/player/walk_right.png',
  'assets/ui/icons/actions/action_feed.png',
  'assets/ui/icons/actions/action_clean.png',
  'assets/ui/icons/actions/action_interact.png',
  'assets/ui/icons/actions/action_rest.png',
  'assets/ui/icons/nav/nav_bestiary.png',
  'assets/ui/icons/nav/nav_home.png',
  'assets/ui/ninepatch/README.md',
  'assets/ui/references/01_world_map_reference.png'
)

foreach ($rel in $required) {
  $path = Join-Path $root $rel
  if (!(Test-Path $path)) { throw "Missing required file: $rel" }
  if ((Get-Item $path).Length -le 0) { throw "Required file is empty: $rel" }
}

$project = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'project.godot')
foreach ($token in @(
  'run/main_scene="res://scenes/world/test_world.tscn"',
  'WorldState="*res://scripts/core/WorldState.gd"',
  'DisplayManager="*res://autoload/display_manager.gd"',
  'SaveManager="*res://autoload/save_manager.gd"',
  'GameState="*res://autoload/game_state.gd"',
  'BattleManager="*res://autoload/battle_manager.gd"',
  'window/size/viewport_width=1280',
  'renderer/rendering_method="gl_compatibility"'
)) {
  if ($project -notmatch [regex]::Escape($token)) { throw "project.godot missing token: $token" }
}

$playerScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/player/player.tscn')
foreach ($token in @(
  '[node name="Player" type="CharacterBody2D"]',
  '[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]',
  '[node name="CollisionShape2D" type="CollisionShape2D" parent="."]',
  '[node name="InteractionArea" type="Area2D" parent="."]'
)) {
  if ($playerScene -notmatch [regex]::Escape($token)) { throw "player.tscn missing token: $token" }
}

if ($playerScene -match [regex]::Escape('[node name="Camera2D" type="Camera2D" parent="."]')) {
  throw 'player.tscn must not contain Camera2D; world scenes own CameraController'
}

$gameplayScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/ui/gameplay_ui.tscn')
if ($gameplayScene -match [regex]::Escape('[node name="BattlePanel"')) {
  throw 'gameplay_ui.tscn must not contain the old in-map BattlePanel; battles use scenes/battle/battle_scene.tscn'
}

# UI-002 baseline: gameplay_ui.tscn currently owns the HUD and transitional
# gameplay panels. Keep these anchor nodes stable until each page is migrated.
foreach ($token in @(
  '[node name="TopHUD" type="HBoxContainer" parent="Root/HUDMargin/ScreenLayout"]',
  '[node name="DexButton" type="Button" parent="Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons"]',
  '[node name="HomeButton" type="Button" parent="Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons"]',
  '[node name="HabitatPanel" type="PanelContainer" parent="Root"]',
  '[node name="EncounterPanel" type="PanelContainer" parent="Root"]',
  '[node name="DexPanel" type="PanelContainer" parent="Root"]',
  '[node name="DexList" type="ItemList" parent="Root/DexPanel/DexMargin/DexBox/DexSplit"]',
  '[node name="HomePanel" type="PanelContainer" parent="Root"]',
  '[node name="HomeList" type="ItemList" parent="Root/HomePanel/HomeMargin/HomeBox/HomeSplit"]',
  '[node name="BattlePrepPanel" type="PanelContainer" parent="Root"]'
)) {
  if ($gameplayScene -notmatch [regex]::Escape($token)) { throw "gameplay_ui.tscn missing UI baseline node: $token" }
}

$modalShellScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/ui/components/game_modal_shell.tscn')
foreach ($token in @(
  '[node name="GameModalShell" type="Control"]',
  '[node name="Dimmer" type="Button" parent="."]',
  '[node name="ModalPanel" type="PanelContainer" parent="ModalCenter"]',
  '[node name="Title" type="Label" parent="ModalCenter/ModalPanel/PanelMargin/PanelLayout/Header"]',
  '[node name="CloseButton" parent="ModalCenter/ModalPanel/PanelMargin/PanelLayout/Header" instance=ExtResource("3_close_button")]',
  '[ext_resource type="PackedScene" path="res://scenes/ui/components/game_close_button.tscn" id="3_close_button"]',
  'theme_override_styles/panel = ExtResource("2_modal_style")'
)) {
  if ($modalShellScene -notmatch [regex]::Escape($token)) { throw "game_modal_shell.tscn missing token: $token" }
}
$portraitCardScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/ui/components/spirit_portrait_card.tscn')
foreach ($token in @('[node name="SpiritPortraitCard" type="Button"]', '[node name="Portrait" type="TextureRect" parent="Card/Layout"]', '[node name="UnknownSilhouette" type="Polygon2D" parent="Card"]')) {
  if ($portraitCardScene -notmatch [regex]::Escape($token)) { throw "spirit_portrait_card.tscn missing token: $token" }
}
$portraitCardScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/ui/components/spirit_portrait_card.gd')
foreach ($token in @('enum CardState', 'NORMAL', 'SELECTED', 'UNKNOWN', 'RESIDENT', 'func set_card_state')) {
  if ($portraitCardScript -notmatch [regex]::Escape($token)) { throw "spirit_portrait_card.gd missing token: $token" }
}

$modalShellStyle = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'resources/themes/ui/modal_shell_panel.tres')
foreach ($token in @('bg_color = Color(1, 0.976471, 0.913725, 1)', 'border_color = Color(0.545098, 0.407843, 0.258824, 1)', 'corner_radius_top_left = 20', 'shadow_size = 12')) {
  if ($modalShellStyle -notmatch [regex]::Escape($token)) { throw "modal_shell_panel.tres missing token: $token" }
}
$modalShellScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/ui/components/game_modal_shell.gd')
foreach ($token in @('signal close_requested', 'func open()', 'func close()', 'ui_cancel', 'NOTIFICATION_WM_GO_BACK_REQUEST')) {
  if ($modalShellScript -notmatch [regex]::Escape($token)) { throw "game_modal_shell.gd missing token: $token" }
}

foreach ($forbidden in @('EncounterObserveButton', '_observe_encounter', '.icon_max_width')) {
  if ($gameplayScene -match [regex]::Escape($forbidden)) { throw "gameplay_ui must not reintroduce UI regression token: $forbidden" }
}

$gameplayScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/ui/gameplay_ui.gd')
foreach ($token in @('SecondaryModalDimmer', 'BattlePrepFooter', 'BattleEmptyLabel', 'BattleScrollHint', 'NOTIFICATION_WM_GO_BACK_REQUEST', 'func refresh_world_hud()', 'func set_area_info(island_name: String, area_name: String)', 'func set_world_hud_visible(is_visible: bool)', 'func show_interaction_prompt', 'func hide_interaction_prompt')) {
  if (($gameplayScene + "`n" + $gameplayScript) -notmatch [regex]::Escape($token)) { throw "gameplay UI missing redesigned behavior token: $token" }
}
if ($gameplayScript -match [regex]::Escape('.icon_max_width')) { throw 'gameplay_ui.gd must not assign Button.icon_max_width at runtime' }

$worldScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/world/test_world.tscn')
foreach ($token in @(
  '[node name="GroundLayer" type="TileMapLayer" parent="."]',
  '[node name="DecorationLayer" type="TileMapLayer" parent="."]',
  '[node name="CollisionLayer" type="TileMapLayer" parent="."]',
  '[node name="TallGrassLayer" type="TileMapLayer" parent="."]',
  '[node name="ForegroundLayer" type="TileMapLayer" parent="."]',
  '[node name="CameraController" type="Camera2D" parent="."]',
  '[node name="SpawnPoints" type="Node2D" parent="."]',
  '[node name="HabitatPoints" type="Node2D" parent="."]',
  '[node name="GameplayUI" parent="." instance=ExtResource(',
  'display_name = "'
)) {
  if ($worldScene -notmatch [regex]::Escape($token)) { throw "test_world.tscn missing token: $token" }
}

$groveScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/world/grove_gate.tscn')
foreach ($token in @(
  'current_exit_id = "south_path"',
  'display_name = "',
  '[node name="SouthExit" parent="." instance=ExtResource('
)) {
  if ($groveScene -notmatch [regex]::Escape($token)) { throw "grove_gate.tscn missing token: $token" }
}

$habitatPointScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/world/habitat_point.tscn')
foreach ($token in @(
  '[node name="PointSprite" type="Sprite2D" parent="."]',
  'radius = 34.0',
  'scale = Vector2(0.42, 0.42)'
)) {
  if ($habitatPointScene -notmatch [regex]::Escape($token)) { throw "habitat_point.tscn missing token: $token" }
}

$sceneExitScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/world/scene_exit.tscn')
foreach ($token in @(
  '[node name="NameLabel" type="Label" parent="."]',
  'size = Vector2(144, 40)',
  'theme_override_font_sizes/font_size = 18'
)) {
  if ($sceneExitScene -notmatch [regex]::Escape($token)) { throw "scene_exit.tscn missing token: $token" }
}

foreach ($rel in @('scenes/world/test_world.tscn', 'scenes/world/grove_gate.tscn')) {
  $sceneContent = Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel)
  if ($sceneContent.Contains('`r`n[ext_resource')) { throw "$rel contains a literal resource newline marker" }
}

$catalogText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'data/catalog/spirits_phase1.json')
foreach ($token in @('leafbun', 'bubblepup', 'emberfox', 'sparkmouse', 'pebbletot', 'cloudchick')) {
  if ($catalogText -notmatch [regex]::Escape($token)) { throw "spirits_phase1.json missing token: $token" }
}

$habitatText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'data/catalog/habitats_phase1.json')
foreach ($token in @('grassland', 'pond', 'warmstone', 'windmill', 'cave', 'cloud')) {
  if ($habitatText -notmatch [regex]::Escape($token)) { throw "habitats_phase1.json missing token: $token" }
}

$scripts = Get-ChildItem -Path $root -Recurse -File -Include *.gd,*.tscn,*.md,*.godot,*.ps1,*.tres |
  ForEach-Object { Get-Content -Raw -Encoding UTF8 $_.FullName }
$joined = $scripts -join "`n"

function New-TextFromCodePoints([int[]]$codePoints) {
  return -join ($codePoints | ForEach-Object { [char]$_ })
}

$playerFacingFiles = @(
  'scenes/ui/gameplay_ui.tscn',
  'scenes/ui/components/game_modal_shell.tscn',
  'scripts/ui/components/game_modal_shell.gd',
  'scenes/ui/components/game_close_button.tscn',
  'scripts/ui/components/game_close_button.gd',
  'scenes/ui/components/filter_chip.tscn',
  'scripts/ui/components/filter_chip.gd',
  'scenes/ui/components/element_badge.tscn',
  'scripts/ui/components/element_badge.gd',
  'resources/themes/ui/modal_shell_panel.tres',
  'scenes/ui/components/stat_meter.tscn',
  'scripts/ui/components/stat_meter.gd',
  'scenes/ui/components/icon_action_button.tscn',
  'scenes/ui/ui_component_showcase.tscn',
  'scripts/ui/components/icon_action_button.gd',
  'scenes/ui/components/spirit_portrait_card.tscn',
  'scripts/ui/components/spirit_portrait_card.gd',
  'scenes/ui/dialogue_ui.tscn',
  'scripts/ui/gameplay_ui.gd',
  'scripts/ui/DialogueUI.gd',
  'autoload/game_state.gd',
  'autoload/battle_manager.gd',
  'autoload/save_manager.gd'
)
$playerFacingText = ($playerFacingFiles | ForEach-Object { Get-Content -Raw -Encoding UTF8 (Join-Path $root $_) }) -join "`n"

$mojibakeTokens = @(
  @(38016, 23680, 20242),
  @(37816, 25118, 22444),
  @(26473, 26047, 27926),
  @(37733, 40515, 22732),
  @(28751, 24531, 30527),
  @(37824, 33333, 28231),
  @(23534, 8364, 28654),
  @(38316, 22250),
  @(28000, 23340, 31899),
  @(29831, 65085, 20751)
) | ForEach-Object { New-TextFromCodePoints $_ }
foreach ($token in $mojibakeTokens) {
  if ($playerFacingText.Contains($token)) {
    throw "Detected mojibake token in player-facing text."
  }
}

$expectedChineseTokens = @(
  @(27426, 36814, 26469, 21040, 33804, 28789, 23567, 23707),
  @(36992, 35831, 20837, 20303),
  @(25361, 25112, 32988, 21033),
  @(22270, 37492, 20250, 35760, 24405)
) | ForEach-Object { New-TextFromCodePoints $_ }
foreach ($token in $expectedChineseTokens) {
  if (!$playerFacingText.Contains($token)) { throw "Missing expected Chinese UI token." }
}

$gdFiles = Get-ChildItem -Path $root -Recurse -File -Filter '*.gd'
foreach ($file in $gdFiles) {
  $text = Get-Content -Raw -Encoding UTF8 $file.FullName
  if ($text -match '(?m)^\s*var\s+[A-Za-z_][A-Za-z0-9_]*\s*:=') {
    throw "GDScript inferred var declaration is forbidden: $($file.FullName)"
  }
}

$autoloadClassNames = @{
  'autoload/save_manager.gd' = 'SaveManager'
  'autoload/game_state.gd' = 'GameState'
  'autoload/battle_manager.gd' = 'BattleManager'
}
foreach ($rel in $autoloadClassNames.Keys) {
  $text = Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel)
  $className = $autoloadClassNames[$rel]
  if ($text -match "(?m)^\s*class_name\s+$className\b") {
    throw "$rel must not declare class_name $className because it hides the autoload singleton"
  }
}

$variantMatches = Select-String -Path $gdFiles.FullName -Pattern ':\s*Variant\b'
foreach ($match in $variantMatches) {
  $relativePath = $match.Path.Substring($root.Length).TrimStart([char]'\', [char]'/').Replace('\', '/')
  $isJsonBoundary = ($relativePath -in @('autoload/save_manager.gd', 'scripts/core/game_catalog.gd')) -and ($match.Line -match 'var\s+parsed:\s*Variant\s*=\s*JSON\.parse_string')
  if (!$isJsonBoundary) {
    throw "Unexpected Variant annotation in $relativePath line $($match.LineNumber): $($match.Line.Trim())"
  }
}

$spirits = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'data/catalog/spirits_phase1.json') | ConvertFrom-Json
if ($spirits.Count -ne 24) { throw "spirits_phase1.json should contain 24 spirits, found $($spirits.Count)" }

$habitats = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'data/catalog/habitats_phase1.json') | ConvertFrom-Json
if ($habitats.Count -ne 6) { throw "habitats_phase1.json should contain 6 habitats, found $($habitats.Count)" }
foreach ($habitat in $habitats) {
  if (@($habitat.encounter_pool).Count -le 0) {
    throw "Habitat $($habitat.habitat_id) has an empty encounter_pool"
  }
}

$battleScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/battle/battle_scene.tscn')
foreach ($token in @(
  '[node name="BattleScene" type="Node2D"]',
  '[node name="PlayerActor"',
  '[node name="EnemyActor"',
  '[node name="BattlePresentation"',
  '[node name="FieldMount" type="Node2D"',
  '[node name="CanvasLayer" type="CanvasLayer"',
  '[node name="BattleUI" type="Control"',
  '[node name="FloatingTextLayer"',
  '[node name="PlayerHpBar" type="TextureProgressBar"',
  '[node name="EnemyHpBar" type="TextureProgressBar"',
  '[node name="EnergyBar" type="TextureProgressBar"',
  '[node name="SkillButton0" type="Button"',
  '[node name="SkillButton3" type="Button"',
  '[node name="ResultPanel" type="PanelContainer"',
  '[node name="DrawButton" type="Button"',
  '[node name="CaptureButton" type="Button"'
)) {
  if ($battleScene -notmatch [regex]::Escape($token)) { throw "battle_scene.tscn missing token: $token" }
}

$battleScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/ui/battle_scene.gd')
foreach ($token in @(
  'const SPIRIT_TEXTURES: Dictionary',
  'const FIELD_SCENES: Dictionary',
  'battlefield_grassland.tscn',
  'BattleManager.use_skill',
  'BattleManager.draw_capture_ball',
  'BattleManager.try_capture_after_battle',
  'BattleManager.return_scene_path',
  'BattleManager.apply_player_result',
  'BattleManager.apply_enemy_result',
  'BattleManager.presentation_timed_out',
  'battle_presentation.setup',
  'DisplayManager.profile_changed.connect(_apply_display_profile)',
  'func _apply_display_profile(profile: DeviceProfile) -> void:',
  'res://assets/spirits/01_ye_tuantuan_',
  'res://assets/spirits/24_jiguang_xiaolong_'
)) {
  if ($battleScript -notmatch [regex]::Escape($token)) { throw "battle_scene.gd missing token: $token" }
}

$battleActorScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/battle/battle_actor.gd')
foreach ($token in @(
  'class_name BattleActor',
  'extends CharacterBody2D',
  'func set_spirit_texture(texture: Texture2D)',
  'func set_spirit_id(spirit_id: String, fallback_texture: Texture2D)',
  'func play_combat_action(action: StringName)',
  'func reset_to_home()',
  'func get_home_position()',
  'TARGET_SPRITE_WIDTH',
  'func set_target_height(height: float)',
  'func set_home_position(home_position: Vector2)'
)) {
  if ($battleActorScript -notmatch [regex]::Escape($token)) { throw "battle_actor.gd missing token: $token" }
}

$battleActorScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/battle/battle_actor.tscn')
foreach ($token in @(
  '[node name="BattleActor" type="CharacterBody2D"]',
  '[node name="SpiritSprite" type="Sprite2D"',
  '[node name="AnimatedSpirit" type="AnimatedSprite2D"',
  '[node name="CollisionShape2D" type="CollisionShape2D"',
  '[node name="Shadow" type="Polygon2D"',
  '[node name="VisualRoot" type="Node2D"',
  '[node name="AnimationPlayer" type="AnimationPlayer"'
)) {
  if ($battleActorScene -notmatch [regex]::Escape($token)) { throw "battle_actor.tscn missing token: $token" }
}

$battleResultScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/battle/battle_action_result.gd')
foreach ($token in @(
  'class_name BattleActionResult',
  'extends RefCounted',
  'attacker_side: String',
  'defender_hp_after: int',
  'defender_defeated: bool',
  'is_heal: bool',
  'log_messages: Array[String]'
)) {
  if ($battleResultScript -notmatch [regex]::Escape($token)) { throw "battle_action_result.gd missing token: $token" }
}

$battlePresScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/battle/battle_presentation.gd')
foreach ($token in @(
  'class_name BattlePresentation',
  'extends Node',
  'func setup(player_actor: BattleActor',
  'func play_action(result: BattleActionResult',
  'func force_cancel()',
  'func is_playing()',
  'LUNGE_DISTANCE',
  'HIT_STOP_DURATION',
  'HP_BAR_DURATION'
)) {
  if ($battlePresScript -notmatch [regex]::Escape($token)) { throw "battle_presentation.gd missing token: $token" }
}

$playerSceneScale = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/player/player.tscn')
if ($playerSceneScale -notmatch [regex]::Escape('scale = Vector2(1.2, 1.2)')) { throw 'player.tscn should keep the approved 1.2 world readability scale' }

$npcSceneScale = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/world/test_npc.tscn')
if ($npcSceneScale -notmatch [regex]::Escape('scale = Vector2(1.05, 1.05)')) { throw 'test_npc.tscn should keep the approved 1.05 world readability scale' }

$mobileProfile = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'resources/mobile_landscape_profile.tres')
if ($mobileProfile -notmatch [regex]::Escape('camera_zoom = Vector2(1.6, 1.6)')) { throw 'mobile profile should use camera_zoom 1.6 for closer landscape view' }

$uiArtCount = @(Get-ChildItem -Path (Join-Path $root 'assets/ui') -Filter '*.png' -File -Recurse -ErrorAction SilentlyContinue).Count
if ($uiArtCount -lt 37) { throw "assets/ui should retain at least the 37 original UI PNG files, found $uiArtCount" }

$themeText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'resources/themes/cozy_theme.tres')
foreach ($token in @(
  'StyleBoxFlat',
  'PanelContainer/styles/panel',
  'Button/styles/normal',
  'Button/styles/hover',
  'Button/styles/pressed',
  'Button/styles/disabled',
  'Label/colors/font_color',
  'ProgressBar/styles/background',
  'ProgressBar/styles/fill',
  'VScrollBar/styles/grabber',
  'TooltipPanel/styles/panel',
  '0.964706, 0.933333, 0.862745',
  '0.286275, 0.227451, 0.164706',
  '0.470588, 0.721569, 0.290196',
  '0.305882, 0.490196, 0.172549',
  '0.839216, 0.678431, 0.447059',
  '0.541176, 0.403922, 0.25098'
)) {
  if ($themeText -notmatch [regex]::Escape($token)) { throw "cozy_theme.tres missing token: $token" }
}

$gameplayUiScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/ui/gameplay_ui.tscn')
foreach ($token in @(
  'theme = ExtResource("2_theme")',
  'res://resources/themes/cozy_theme.tres',
  'res://assets/ui/icons/nav/nav_bestiary.png',
  'res://assets/ui/icons/nav/nav_home.png',
  'res://assets/ui/icons/actions/action_feed.png',
  'res://assets/ui/icons/actions/action_clean.png',
  '[node name="Content" type="VBoxContainer" parent="Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons/DexButton"]',
  'AreaIntroToast',
  'QuestCard',
  'HUDMargin',
  'custom_minimum_size = Vector2(0, 60)'
)) {
  if ($gameplayUiScene -notmatch [regex]::Escape($token)) { throw "gameplay_ui.tscn missing clear UI token: $token" }
}

$battleUiScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/battle/battle_scene.tscn')
$battlefieldScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/battle/battlefield.gd')
foreach ($token in @('class_name Battlefield', 'extends Node2D')) {
  if ($battlefieldScript -notmatch [regex]::Escape($token)) { throw "battlefield.gd missing token: $token" }
}
$battleFieldScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/battle/fields/battlefield_grassland.tscn')
foreach ($token in @(
  '[node name="BackgroundFar" type="Node2D"',
  '[node name="BackgroundMid" type="Node2D"',
  '[node name="GroundLayer" type="Node2D"',
  '[node name="PlayerPlatform" type="Node2D"',
  '[node name="EnemyPlatform" type="Node2D"',
  '[node name="EnvironmentFront" type="Node2D"',
  'grassland_ground_01.png',
  'tree_small_a.png',
  'wildflower_cluster.png',
  'bush_cluster_large.png'
)) {
  if ($battleFieldScene -notmatch [regex]::Escape($token)) { throw "battlefield_grassland.tscn missing token: $token" }
}
if ($battleUiScene -match '\[node name="(Background|SkyGradient|GroundLine|PlayerPlatform|EnemyPlatform)" type="ColorRect"') {
  throw 'battle_scene.tscn must not contain the old ColorRect battle background or platform strips'
}
if ($battleUiScene -match '\[node name="BattleTitle"') {
  throw 'battle_scene.tscn must not contain the permanent BattleTitle label'
}
$battleUiScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/battle/battle_scene.tscn')
foreach ($token in @(
  'theme = ExtResource("2_theme")',
  'res://resources/themes/cozy_theme.tres',
  '[node name="PlayerStatusCard" type="PanelContainer"',
  '[node name="EnemyStatusCard" type="PanelContainer"',
  '[node name="PlayerHpBar" type="TextureProgressBar"',
  '[node name="EnemyHpBar" type="TextureProgressBar"',
  '[node name="EnergyBar" type="TextureProgressBar"',
  'texture_progress = SubResource("HpBarTexture")',
  'texture_progress = SubResource("EnergyBarTexture")',
  'columns = 4',
  'custom_minimum_size = Vector2(244, 112)',
  '[node name="SkillDescriptionPanel" type="PanelContainer"'
)) {
  if ($battleUiScene -notmatch [regex]::Escape($token)) { throw "battle_scene.tscn missing clear UI token: $token" }
}

$dialogueScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/ui/dialogue_ui.tscn')
foreach ($token in @(
  '[node name="Root" type="PanelContainer" parent="."]',
  'theme = ExtResource("2_theme")',
  'res://resources/themes/cozy_theme.tres'
)) {
  if ($dialogueScene -notmatch [regex]::Escape($token)) { throw "dialogue_ui.tscn missing clear UI token: $token" }
}

$uiSceneText = @($gameplayUiScene, $battleUiScene, $dialogueScene) -join "`n"
foreach ($forbidden in @(
  'StyleBoxTexture',
  'hud_resource_bar.png',
  'button_go.png',
  'panel_large.png',
  'panel_medium.png',
  'panel_wide.png',
  'dialog_panel_group.png',
  'assets/ui/groups/',
  'assets/ui/references/'
)) {
  if ($uiSceneText -match [regex]::Escape($forbidden)) { throw "Forbidden stretched/cropped UI skin reference remains: $forbidden" }
}

foreach ($iconLine in Select-String -Path (Join-Path $root 'scenes/ui/gameplay_ui.tscn') -Pattern 'icon_max_width\s*=\s*(\d+)') {
  $iconSize = [int]([regex]::Match($iconLine.Line, '\d+').Value)
  if ($iconSize -lt 20 -or $iconSize -gt 36) { throw "Button icon width must stay within 20..36 px: $($iconLine.Line.Trim())" }
}


$componentDoc = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'docs/ui-component-library.md')
foreach ($token in @(
  'res://resources/themes/cozy_theme.tres',
  'PanelContainer',
  'MarginContainer',
  'VBoxContainer',
  'HBoxContainer',
  'GridContainer',
  'ScrollContainer',
  'TextureProgressBar',
  'FORBIDDEN_STRETCHED_CONCEPT_SKIN',
  'StyleBoxTexture',
  'res://assets/ui/ninepatch/'
)) {
  if ($componentDoc -notmatch [regex]::Escape($token)) { throw "ui-component-library.md missing token: $token" }
}

$ninepatchReadme = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'assets/ui/ninepatch/README.md')
foreach ($token in @('dialog_panel', 'large_panel', 'card_panel', 'primary_button', 'FORBIDDEN_STRETCHED_CONCEPT_SKIN')) {
  if ($ninepatchReadme -notmatch [regex]::Escape($token)) { throw "NinePatch README missing token: $token" }
}
$tilesetText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'tilesets/world_tiles.tres')
if ($tilesetText -match [regex]::Escape('assets/ui/references/01_world_map_reference.png')) { throw 'World map reference image must not be used as TileSet texture' }

$spiritArtCount = @(Get-ChildItem -Path (Join-Path $root 'assets/spirits') -Filter '*.png' -File -ErrorAction SilentlyContinue).Count
if ($spiritArtCount -ne 24) { throw "assets/spirits should contain 24 png files, found $spiritArtCount" }

$explorationArtCount = @(Get-ChildItem -Path (Join-Path $root 'assets/exploration_points') -Filter '*.png' -File -ErrorAction SilentlyContinue).Count
if ($explorationArtCount -ne 6) { throw "assets/exploration_points should contain 6 png files, found $explorationArtCount" }

$incomingWorldArtCount = @(Get-ChildItem -Path (Join-Path $root 'assets/incoming/world') -Filter '*.png' -File -Recurse -ErrorAction SilentlyContinue).Count
if ($incomingWorldArtCount -lt 18) { throw "assets/incoming/world should keep the incoming world art candidates" }

$windPlazaTileCount = @(Get-ChildItem -Path (Join-Path $root 'assets/world/tiles') -Filter '*.png' -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match 'tiles\\(grass|road)' }).Count
if ($windPlazaTileCount -lt 5) { throw "wind plaza should keep at least 5 formal grass/road tile png files" }

$windPlazaPropCount = @(Get-ChildItem -Path (Join-Path $root 'assets/world/props/plaza') -Filter '*.png' -File -ErrorAction SilentlyContinue).Count
if ($windPlazaPropCount -lt 5) { throw "wind plaza should keep at least 5 formal plaza prop png files" }

$windPlazaTileset = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'tilesets/wind_plaza_tiles.tres')
foreach ($token in @('grass_base_01.png', 'grass_base_02.png', 'grass_base_03.png', 'plaza_ground.png', 'road_base.png')) {
  if ($windPlazaTileset -notmatch [regex]::Escape($token)) { throw "wind_plaza_tiles.tres missing token: $token" }
}

$testWorldScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/world/test_world.tscn')
foreach ($token in @('VisualGroundLayer', 'PathLayer', 'GroundDetailLayer', 'BackDecorationLayer', 'YSortEntities', 'res://tilesets/wind_plaza_tiles.tres')) {
  if ($testWorldScene -notmatch [regex]::Escape($token)) { throw "test_world.tscn missing wind plaza token: $token" }
}

$grasslandTileCount = @(Get-ChildItem -Path (Join-Path $root 'assets/world/tiles/grass') -Filter '*.png' -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @('grassland_ground_01.png', 'grassland_ground_02.png', 'tall_grass_tile.png', 'grass_path_edge.png') }).Count
if ($grasslandTileCount -ne 4) { throw "grassland habitat should keep 4 formal grassland tile png files" }

$grasslandPropCount = @(Get-ChildItem -Path (Join-Path $root 'assets/world/props/grassland') -Filter '*.png' -File -ErrorAction SilentlyContinue).Count
if ($grasslandPropCount -lt 6) { throw "grassland habitat should keep at least 6 formal prop png files" }

foreach ($token in @('grassland_ground_01.png', 'grassland_ground_02.png', 'tall_grass_tile.png', 'grass_path_edge.png')) {
  if ($windPlazaTileset -notmatch [regex]::Escape($token)) { throw "wind_plaza_tiles.tres missing grassland token: $token" }
}

$grasslandRegionScene = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scenes/world/regions/grassland_region.tscn')
foreach ($token in @('grassland_decor_cluster.tscn', 'MainGrasslandDecor', 'GrasslandDecorWest')) {
  if ($grasslandRegionScene -notmatch [regex]::Escape($token)) { throw "grassland_region.tscn missing token: $token" }
}

foreach ($token in @(
  'set_next_spawn(scene_path: String, spawn_id: String)',
  'toggle_dialogue(speaker: String, text: String)',
  'target_scene_path',
  'target_spawn_id',
  'display_name: String',
  'NameLabel',
  'HABITAT_TEXTURES: Dictionary',
  'PointSprite',
  'move_speed: float',
  'idle_down',
  'walk_right',
  'TileMapLayer',
  'CanvasLayer',
  'Area2D',
  'class_name DeviceProfile',
  'signal profile_changed(profile: DeviceProfile)',
  'extends Camera2D',
  'target_path: NodePath',
  '@onready var camera_controller: Camera2D = $CameraController',
  'Vector2i(96, 54)',
  'DisplayManager.profile_changed.connect(_apply_display_profile)',
  'BASE_PANEL_TITLE_FONT: int = 28',
  'BASE_SPEAKER_FONT: int = 26',
  'BASE_TITLE_FONT: int = 38',
  'class_name GameCatalog',
  'signal save_loaded(save_data: Dictionary)',
  'signal ui_state_changed(panel: String)',
  'signal battle_state_changed',
  'class_name SpiritData',
  'class_name SpiritSkill',
  'class_name HabitatData',
  'BATTLE_CAPTURE_BALLS',
  'attempt_direct_capture',
  'draw_capture_ball',
  'set_return_scene_path',
  'BATTLE_SCENE_PATH',
  'class_name BattleActor',
  'class_name BattleActionResult',
  'class_name BattlePresentation',
  'signal presentation_timed_out',
  'ACTION_TIMEOUT_SECONDS',
  'pending_result: BattleActionResult',
  'func play_action(result: BattleActionResult',
  'func force_cancel()',
  'Mobile Landscape',
  'Desktop'
)) {
  if ($joined -notmatch [regex]::Escape($token)) { throw "Missing expected token: $token" }
}

$worldScript = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'scripts/world/world_scene.gd')
if ($worldScript -match [regex]::Escape('player.get_node("Camera2D")')) {
  throw 'world camera limits must not look up Player/Camera2D'
}
if ($worldScript -notmatch [regex]::Escape('get_node_or_null("YSortEntities/Player")') -or $worldScript -notmatch [regex]::Escape('get_node_or_null("Player")')) {
  throw 'shared world scene script must support both YSortEntities/Player and root Player layouts'
}

$godotCandidates = @(
  'C:\Program Files\Godot\Godot_v4.7-stable_win64_console.exe',
  (Get-Command godot4 -ErrorAction SilentlyContinue).Source,
  (Get-Command godot -ErrorAction SilentlyContinue).Source,
  'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe'
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$godotExe = $godotCandidates | Select-Object -First 1
if ($godotExe) {
  $appData = Join-Path $root '.godot_check_appdata'
  $localAppData = Join-Path $root '.godot_check_localappdata'
  $logPath = Join-Path $root '.godot-phase1-check.log'
  New-Item -ItemType Directory -Force $appData | Out-Null
  New-Item -ItemType Directory -Force $localAppData | Out-Null
  $previousAppData = $env:APPDATA
  $previousLocalAppData = $env:LOCALAPPDATA
  try {
    $env:APPDATA = $appData
    $env:LOCALAPPDATA = $localAppData
    $stdoutPath = Join-Path $root '.godot-phase1-check.out.log'
    $stderrPath = Join-Path $root '.godot-phase1-check.err.log'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $godotExe
    $psi.Arguments = "--headless --log-file `"$logPath`" --path `"$root`" --script res://scripts/verify_phase1_rules.gd"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $stdout | Out-File -FilePath $stdoutPath -Encoding UTF8
    $stderr | Out-File -FilePath $stderrPath -Encoding UTF8
    $process = [PSCustomObject]@{ ExitCode = $proc.ExitCode }
    $output = @()
    if (Test-Path $stdoutPath) { $output += Get-Content -Raw -Encoding UTF8 $stdoutPath }
    if (Test-Path $stderrPath) { $output += Get-Content -Raw -Encoding UTF8 $stderrPath }
    if ($process.ExitCode -ne 0) {
      $output | Write-Host
      throw "Godot phase-1 runtime check failed with exit code $($process.ExitCode)"
    }
    if (($output -join "`n") -notmatch 'phase-1 rules runtime check passed') {
      $output | Write-Host
      throw 'Godot phase-1 runtime check did not print the success marker'
    }
  }
  finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    foreach ($pathToClean in @($appData, $localAppData, $logPath, (Join-Path $root '.godot-phase1-check.out.log'), (Join-Path $root '.godot-phase1-check.err.log'))) {
      if (Test-Path $pathToClean) {
        try {
          if ((Get-Item $pathToClean).PSIsContainer) {
            [System.IO.Directory]::Delete($pathToClean, $true)
          } else {
            [System.IO.File]::Delete($pathToClean)
          }
        } catch {
          # File may still be locked by Godot process; ignore cleanup errors
        }
      }
    }
  }
} else {
  Write-Host 'Godot executable not found; skipped phase-1 runtime script check.'
}

Write-Host 'sprite-island-godot phase-1 rule-migration check passed.'