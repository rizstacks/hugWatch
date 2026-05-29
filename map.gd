extends Node3D

func build_map() -> void:
	box("Floor", Vector3(120, 0.4, 90), Vector3(0, -0.2, 0), Color(0.32, 0.32, 0.36))
	box("Ceiling", Vector3(120, 0.4, 90), Vector3(0, 6, 0), Color(0.14, 0.14, 0.17))

	box("Back Wall", Vector3(120, 6, 0.5), Vector3(0, 3, -45), Color(0.65, 0.62, 0.55))
	box("Front Wall", Vector3(120, 6, 0.5), Vector3(0, 3, 45), Color(0.65, 0.62, 0.55))
	box("Left Wall", Vector3(0.5, 6, 90), Vector3(-60, 3, 0), Color(0.65, 0.62, 0.55))
	box("Right Wall", Vector3(0.5, 6, 90), Vector3(60, 3, 0), Color(0.65, 0.62, 0.55))

	box("Hall Left Wall", Vector3(0.4, 5, 80), Vector3(-8, 2.5, 0), Color(0.45, 0.47, 0.52))
	box("Hall Right Wall", Vector3(0.4, 5, 80), Vector3(8, 2.5, 0), Color(0.45, 0.47, 0.52))

	room("Classroom A", Vector3(-32, 0, -22), Color(0.72, 0.68, 0.55))
	classroom_props(Vector3(-32, 0, -22), "A")

	room("Classroom B", Vector3(32, 0, -22), Color(0.72, 0.68, 0.55))
	classroom_props(Vector3(32, 0, -22), "B")

	room("Science Lab", Vector3(-32, 0, 18), Color(0.52, 0.68, 0.62))
	lab_props(Vector3(-32, 0, 18))

	room("Pool Room", Vector3(32, 0, 18), Color(0.45, 0.58, 0.75))
	pool_props(Vector3(32, 0, 18))

	for i in range(15):
		box("Locker L", Vector3(0.8, 3, 1.2), Vector3(-7.4, 1.5, -36 + i * 5), Color(0.08, 0.15, 0.45))
		box("Locker R", Vector3(0.8, 3, 1.2), Vector3(7.4, 1.5, -36 + i * 5), Color(0.08, 0.15, 0.45))

	for i in range(8):
		pickup("Book", Vector3(0.8, 0.15, 0.6), Vector3(-2, 0.5, -32 + i * 8), Color(0.85, 0.1, 0.1), 0.6)
		pickup("Backpack", Vector3(1.2, 0.8, 0.7), Vector3(2.5, 0.5, -30 + i * 8), Color(0.04, 0.04, 0.08), 1.5)
		pickup("Trash Can", Vector3(1, 1.5, 1), Vector3(5, 0.8, -32 + i * 8), Color(0.1, 0.1, 0.1), 2.0)

	add_lights()

func room(n: String, c: Vector3, wall_color: Color) -> void:
	var x := c.x
	var z := c.z

	box(n + " Back Wall", Vector3(24, 5, 0.4), Vector3(x, 2.5, z - 10), wall_color)
	box(n + " Left Wall", Vector3(0.4, 5, 20), Vector3(x - 12, 2.5, z), wall_color)
	box(n + " Right Wall", Vector3(0.4, 5, 20), Vector3(x + 12, 2.5, z), wall_color)
	box(n + " Front Left", Vector3(8, 5, 0.4), Vector3(x - 8, 2.5, z + 10), wall_color)
	box(n + " Front Right", Vector3(8, 5, 0.4), Vector3(x + 8, 2.5, z + 10), wall_color)

func classroom_props(c: Vector3, label: String) -> void:
	var x0 := c.x
	var z0 := c.z

	box("Whiteboard " + label, Vector3(9, 2, 0.15), Vector3(x0, 2.8, z0 - 9.7), Color(0.9, 0.95, 0.9))
	box("Teacher Desk " + label, Vector3(5, 1, 2), Vector3(x0, 0.5, z0 - 6.5), Color(0.42, 0.22, 0.1))

	for row in range(3):
		for col in range(3):
			var x := x0 - 6 + col * 6
			var z := z0 - 1 + row * 4
			box("Desk", Vector3(3, 0.8, 1.8), Vector3(x, 0.4, z), Color(0.48, 0.25, 0.12))
			
func lab_props(c: Vector3) -> void:
	var x0 := c.x
	var z0 := c.z

	box("Lab Board", Vector3(9, 2, 0.15), Vector3(x0, 2.8, z0 - 9.7), Color(0.9, 0.95, 0.9))

	for i in range(3):
		box("Lab Table", Vector3(7, 1, 2), Vector3(x0, 0.5, z0 - 4 + i * 5), Color(0.35, 0.35, 0.38))

func pool_props(c: Vector3) -> void:
	var x0 := c.x
	var z0 := c.z

	box("Pool Water", Vector3(15, 0.2, 9), Vector3(x0, 0.05, z0), Color(0.08, 0.45, 0.85))
	box("Pool Edge Back", Vector3(17, 0.5, 0.5), Vector3(x0, 0.25, z0 - 5), Color(0.9, 0.9, 0.85))
	box("Pool Edge Front", Vector3(17, 0.5, 0.5), Vector3(x0, 0.25, z0 + 5), Color(0.9, 0.9, 0.85))
	box("Pool Edge Left", Vector3(0.5, 0.5, 10), Vector3(x0 - 8.5, 0.25, z0), Color(0.9, 0.9, 0.85))
	box("Pool Edge Right", Vector3(0.5, 0.5, 10), Vector3(x0 + 8.5, 0.25, z0), Color(0.9, 0.9, 0.85))

	for i in range(5):
		box("Pool Bench", Vector3(3, 0.5, 1), Vector3(x0 - 7 + i * 3.5, 0.4, z0 + 7), Color(0.4, 0.25, 0.12))
