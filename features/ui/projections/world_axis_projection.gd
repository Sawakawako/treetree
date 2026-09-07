class_name WorldAxisProjection
extends RefCounted

static func gap_text(state: GameState) -> String:
	var remaining := maxi(RealmCatalog.all_realms().size() - state.realm_echoes.size(), 0)
	if remaining > 0:
		return "世界之轴：还差 %d 个界域" % remaining
	if not state.lingua_nodes.has(&"world_breath"):
		return "世界之轴：天地一息未点亮"
	return "世界之轴：九界正在同一口风里呼吸"
