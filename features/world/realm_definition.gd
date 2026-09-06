class_name RealmDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var subtitle: String
@export_enum("crown", "trunk", "root") var tree_domain: String = "trunk"
@export var prerequisites: Array[StringName] = []
@export var required_races: Array[StringName] = []
@export var required_lingua_node: StringName = &""
@export var required_relic: int = 0
@export var min_growth: float = 0.0
@export var min_root_depth: int = 0
@export var sap_cost: float = 0.0
@export var memory_cost: float = 0.0
@export var faith_cost: float = 0.0
@export_multiline var discovery_text: String
