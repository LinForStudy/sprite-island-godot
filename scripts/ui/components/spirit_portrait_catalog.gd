class_name SpiritPortraitCatalog

const PATHS: Dictionary = {
	"leafbun": "res://assets/spirits/01_ye_tuantuan_叶团团.png", "sproutdeer": "res://assets/spirits/02_ya_jiaolu_芽角鹿.png", "vinerabbit": "res://assets/spirits/03_teng_ertu_藤耳兔.png", "bloomwhale": "res://assets/spirits/04_hua_mianjing_花眠鲸.png", "bubblepup": "res://assets/spirits/05_paopao_wang_泡泡汪.png", "moonfish": "res://assets/spirits/06_yue_qiyu_月鳍鱼.png", "rainseal": "res://assets/spirits/07_yu_ling_haibao_雨铃海豹.png", "starjelly": "res://assets/spirits/08_xing_mian_shuimu_星眠水母.png", "emberfox": "res://assets/spirits/09_nuan_weihu_暖尾狐.png", "lanterncub": "res://assets/spirits/10_deng_rongxiong_灯绒熊.png", "candlemoth": "res://assets/spirits/11_zhu_chie_烛翅蛾.png", "sunlion": "res://assets/spirits/12_ri_mianshi_日冕狮.png", "sparkmouse": "res://assets/spirits/13_shan_doushu_闪豆鼠.png", "bellvolt": "res://assets/spirits/14_ling_dianmao_铃电猫.png", "coilowl": "res://assets/spirits/15_xianquan_gu_线圈咕.png", "stormalpaca": "res://assets/spirits/16_lei_rongtuo_雷绒驼.png", "pebbletot": "res://assets/spirits/17_yuan_shizai_圆石仔.png", "mudturtle": "res://assets/spirits/18_ni_ke_gui_泥壳龟.png", "crystalbadger": "res://assets/spirits/19_jing_bi_huan_晶鼻獾.png", "mountainseed": "res://assets/spirits/20_shan_xinzhong_山心种.png", "cloudchick": "res://assets/spirits/21_yun_tuanjiu_云团啾.png", "kitehare": "res://assets/spirits/22_fengzheng_tu_风筝兔.png", "whistlecrane": "res://assets/spirits/23_shao_yuhe_哨羽鹤.png", "auroradrake": "res://assets/spirits/24_jiguang_xiaolong_极光小龙.png"
}

static func get_texture(spirit_id: String) -> Texture2D:
	var path: String = String(PATHS.get(spirit_id, ""))
	return load(path) as Texture2D if not path.is_empty() else null
