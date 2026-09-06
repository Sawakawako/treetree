class_name MiracleDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var required_realms: Array[StringName] = []
@export var required_lingua_node: StringName = &""
@export var required_life_level: int = 0
@export var faith_costs: Array[int] = []
@export var max_uses: int = 0
@export_enum("none", "race") var target_mode: String = "none"
@export_multiline var first_text: String
@export_multiline var repeat_text: String
