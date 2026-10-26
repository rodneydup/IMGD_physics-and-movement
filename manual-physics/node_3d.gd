extends Node3D

var spheres = [0]
var num = 100
var gravity = 10

func _ready():
	#add_child(Sphere.new())
	spheres.resize(num)
	for i in num:
		spheres[i] = Sphere.new(1, Vector3(r(-1,1),r(-1,1),r(-1,1)), Color.from_hsv(float(i)/num,1.0,1.0), 0.05)
		print(spheres[i].material_override.albedo_color)
	for i in spheres:
		add_child(i)

func _process(delta):
	for i in range(0, num):
		for j in range(i+1,num):
			var r = spheres[i].position - spheres[j].position
			var rhat = r.normalize()
			var distsqr = r.dot(r)
			
			

func r(min, max):
	return randf_range(min, max)
