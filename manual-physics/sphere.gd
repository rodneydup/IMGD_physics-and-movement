class_name Sphere extends MeshInstance3D

var mass = 1
var vel = Vector3(0,0,0)

func _init(_mass = 1, _position = Vector3(0,0,0), _color:Color = Color("white"), _size = 1):
	mesh = SphereMesh.new()
	mesh.radius = _size
	mesh.height = _size * 2
	material_override = StandardMaterial3D.new()
	material_override.albedo_color = _color
	material_override.roughness = 0.4
	mass = _mass
	position = _position
	
