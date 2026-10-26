extends Node3D


var spheres = [0] # array that will hold our spheres
var num = 100 # Number of spheres
var g = 0.01 # gravity

# This is called when the program loads
func _ready():
	# All we are doing here is adding "num" amount of spheres to our array. 
	# "Sphere" is a custom class I made. You can look at it by ctrl+clicking on "Sphere".
	spheres.resize(num)
	# Set up the "Sun" separately
	spheres[0] = Sphere.new(100, Vector3(0,0,0), Color.from_hsv(0.2,1.0,1.0), 0.3)
	for i in range(1,num):
		var initial_pos = Vector3(r(-2,2), 0, r(-2,2))*2
		spheres[i] = Sphere.new(0.2, initial_pos, Color.from_hsv(float(i)/num,1.0,1.0), 0.02)
		# Set initial velocity perpendicular to the sun on the X/Z Plane (reference: https://en.wikipedia.org/wiki/Orbital_speed)
		spheres[i].velocity = sqrt(g * spheres[0].mass / sqrt(initial_pos.dot(initial_pos))) * initial_pos.cross(Vector3(0,1,0)).normalized()
	for i in spheres:
		add_child(i)

# this is called every frame
func _process(delta):
	# We set up a nested for loop to compare every pair of spheres
	for i in range(0, num):
		for j in range(i+1,num):
			# r is the vector between the spheres
			var r = spheres[i].position - spheres[j].position
			# rcubed is the magnitude of the vector cubed
			var rcubed = pow(sqrt(r.dot(r)),3)
			# a constraint to avoid spheres flying apart
			if rcubed < 0.01:
				continue # "continue" means skip the rest of this iteration of the loop
			# https://en.wikipedia.org/wiki/Newton%27s_law_of_universal_gravitation#Vector_form
			var f = (g * spheres[i].mass * spheres[j].mass / rcubed) * r
			# add the acceleration to each particle (inverted direction for the first particle)
			if i > 0: # keep the sun immobile
				spheres[i].acceleration -= f
			spheres[j].acceleration += f
			
	# integration using a "backward Euler method"
	for i in spheres:
		i.velocity += i.acceleration / i.mass * delta
		i.position += i.velocity * delta
		# clear the acceleration after integration - we don't want to carry this forward!
		i.acceleration = Vector3(0,0,0)
			

# just making a custom function to call random range with shorter syntax
func r(min, max):
	return randf_range(min, max)
