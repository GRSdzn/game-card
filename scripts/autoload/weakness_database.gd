extends Node

var weaknesses: Dictionary[StringName, WeaknessData] = {}

func _ready() -> void:
	reload_weaknesses()

func reload_weaknesses() -> void:
	weaknesses.clear()
	var file_names := ResourceLoader.list_directory("res://data/weaknesses")
	if file_names.is_empty():
		push_error("WeaknessDatabase: no weakness resources found in res://data/weaknesses")
		return
	file_names.sort()
	for file_name in file_names:
		if not file_name.ends_with(".tres"):
			continue
		var resource := ResourceLoader.load("res://data/weaknesses/%s" % file_name)
		if resource is WeaknessData:
			if resource.id.is_empty():
				push_error("WeaknessDatabase: weakness '%s' has an empty ID." % file_name)
			elif weaknesses.has(resource.id):
				push_error("WeaknessDatabase: duplicate weakness ID '%s'." % resource.id)
			else:
				weaknesses[resource.id] = resource

func get_weakness(id: StringName) -> WeaknessData:
	return weaknesses.get(id) as WeaknessData
