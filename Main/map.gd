extends Node3D

# ─────────────────────────────────────────────
#  LOW POLY SCHOOL MAP  —  drop onto a Node3D
# ─────────────────────────────────────────────

func _ready() -> void:
	build_map()

# ══════════════════════════════════════════════
#  ENTRY POINT
# ══════════════════════════════════════════════
func build_map() -> void:
	build_shell()
	build_hallway()
	build_lockers()
	build_hallway_props()
	build_classroom("Classroom A",  Vector3(-34, 0, -22), Color(0.72, 0.68, 0.55))
	build_classroom("Classroom B",  Vector3( 34, 0, -22), Color(0.72, 0.68, 0.55))
	build_science_lab(Vector3(-34, 0, 20))
	build_pool_room(Vector3( 34, 0, 20))
	build_library(Vector3(0, 0, -22))
	build_cafeteria(Vector3(0, 0, 20))
	build_bathrooms()
	build_staircase(Vector3(-56, 0, 0))
	build_second_floor()
	add_lights()

# ══════════════════════════════════════════════
#  OUTER SHELL
# ══════════════════════════════════════════════
func build_shell() -> void:
	# Floor
	box("Floor",    Vector3(130, 0.4,  100), Vector3(0, -0.2,  0),  Color(0.30, 0.30, 0.34))
	# Ceiling
	box("Ceiling",  Vector3(130, 0.4,  100), Vector3(0,  6.0,  0),  Color(0.14, 0.14, 0.17))
	# Outer walls
	box("Wall Back",  Vector3(130, 6.4, 0.5), Vector3(0,  3.0, -50), Color(0.62, 0.59, 0.52))
	box("Wall Front", Vector3(130, 6.4, 0.5), Vector3(0,  3.0,  50), Color(0.62, 0.59, 0.52))
	box("Wall Left",  Vector3(0.5, 6.4, 100), Vector3(-65, 3.0, 0),  Color(0.62, 0.59, 0.52))
	box("Wall Right", Vector3(0.5, 6.4, 100), Vector3( 65, 3.0, 0),  Color(0.62, 0.59, 0.52))
	# Baseboard trim
	for side in [[-65,0],[65,0],[0,-50],[0,50]]:
		pass  # visual detail via lockers / room walls

# ══════════════════════════════════════════════
#  CENTRAL HALLWAY
# ══════════════════════════════════════════════
func build_hallway() -> void:
	# Inner hallway walls (corridor between rooms)
	box("Hall Wall L", Vector3(0.4, 5.0, 88), Vector3(-10, 2.5,  0), Color(0.50, 0.50, 0.55))
	box("Hall Wall R", Vector3(0.4, 5.0, 88), Vector3( 10, 2.5,  0), Color(0.50, 0.50, 0.55))
	# Hall floor stripe
	box("Hall Floor", Vector3(20, 0.05, 88), Vector3(0, 0.02, 0), Color(0.26, 0.26, 0.30))
	# Ceiling tiles in hallway
	for i in range(11):
		box("Hall Ceiling Tile", Vector3(18, 0.08, 6), Vector3(0, 5.9, -40 + i * 8), Color(0.18, 0.18, 0.20))

# ══════════════════════════════════════════════
#  LOCKERS
# ══════════════════════════════════════════════
func build_lockers() -> void:
	for i in range(18):
		var z := -42.0 + i * 5.0
		# Left bank
		box("LockerL Body", Vector3(0.7, 3.2, 1.1), Vector3(-9.3, 1.6, z), Color(0.08, 0.14, 0.46))
		box("LockerL Door", Vector3(0.05, 2.8, 0.9), Vector3(-8.95, 1.4, z), Color(0.10, 0.18, 0.55))
		box("LockerL Handle", Vector3(0.08, 0.12, 0.08), Vector3(-8.88, 1.5, z + 0.25), Color(0.8, 0.8, 0.8))
		# Right bank
		box("LockerR Body", Vector3(0.7, 3.2, 1.1), Vector3( 9.3, 1.6, z), Color(0.08, 0.14, 0.46))
		box("LockerR Door", Vector3(0.05, 2.8, 0.9), Vector3( 8.95, 1.4, z), Color(0.10, 0.18, 0.55))
		box("LockerR Handle", Vector3(0.08, 0.12, 0.08), Vector3( 8.88, 1.5, z + 0.25), Color(0.8, 0.8, 0.8))

# ══════════════════════════════════════════════
#  HALLWAY PROPS
# ══════════════════════════════════════════════
func build_hallway_props() -> void:
	# Benches along hallway
	for i in range(5):
		var z := -30.0 + i * 14.0
		box("Bench L Seat", Vector3(4, 0.2, 1.2), Vector3(-7, 0.5, z), Color(0.38, 0.22, 0.10))
		box("Bench L Leg1", Vector3(0.2, 0.5, 0.2), Vector3(-8.5, 0.25, z - 0.4), Color(0.25, 0.15, 0.08))
		box("Bench L Leg2", Vector3(0.2, 0.5, 0.2), Vector3(-5.5, 0.25, z - 0.4), Color(0.25, 0.15, 0.08))
		box("Bench L Leg3", Vector3(0.2, 0.5, 0.2), Vector3(-8.5, 0.25, z + 0.4), Color(0.25, 0.15, 0.08))
		box("Bench L Leg4", Vector3(0.2, 0.5, 0.2), Vector3(-5.5, 0.25, z + 0.4), Color(0.25, 0.15, 0.08))
		box("Bench R Seat", Vector3(4, 0.2, 1.2), Vector3( 7, 0.5, z), Color(0.38, 0.22, 0.10))

	# Trash cans
	for i in range(6):
		var z := -35.0 + i * 14.0
		box("Trash L", Vector3(0.9, 1.4, 0.9), Vector3(-9.0, 0.7, z), Color(0.12, 0.12, 0.12))
		box("Trash R", Vector3(0.9, 1.4, 0.9), Vector3( 9.0, 0.7, z), Color(0.12, 0.12, 0.12))

	# Backpacks & books scattered
	for i in range(10):
		var z := -38.0 + i * 8.0
		pickup("Book",     Vector3(0.8, 0.15, 0.6), Vector3(-2.0, 0.5, z),      Color(0.85, 0.10, 0.10), 0.6)
		pickup("Backpack", Vector3(1.2, 0.8,  0.7), Vector3( 2.5, 0.5, z + 1.5), Color(0.04, 0.04, 0.08), 1.5)

	# Water fountain
	box("Fountain Base", Vector3(1.2, 1.1, 0.6), Vector3(-9.5, 0.55, 5), Color(0.75, 0.75, 0.78))
	box("Fountain Bowl", Vector3(0.9, 0.15, 0.45), Vector3(-9.5, 1.15, 5), Color(0.88, 0.88, 0.92))
	box("Fountain Pipe", Vector3(0.1, 0.3, 0.1), Vector3(-9.5, 1.2, 4.8), Color(0.6, 0.6, 0.65))

	# Notice board
	box("Notice Board Back", Vector3(4, 2.2, 0.1), Vector3(0, 2.8, -49.8), Color(0.45, 0.28, 0.10))
	box("Notice Board Face", Vector3(3.6, 1.9, 0.06), Vector3(0, 2.8, -49.72), Color(0.88, 0.84, 0.72))
	for n in range(6):
		box("Notice Pin", Vector3(0.5, 0.7, 0.04),
			Vector3(-1.4 + (n % 3) * 1.4, 2.5 + (n / 3) * 0.85, -49.66),
			Color(randf_range(0.5,1.0), randf_range(0.1,0.5), 0.1))

	# Fire extinguisher
	box("Extinguisher", Vector3(0.3, 1.0, 0.3), Vector3(9.5, 0.8, -48), Color(0.85, 0.05, 0.05))
	box("Extinguisher Bracket", Vector3(0.5, 0.1, 0.2), Vector3(9.5, 1.35, -48), Color(0.4, 0.4, 0.4))

# ══════════════════════════════════════════════
#  CLASSROOM (reusable)
# ══════════════════════════════════════════════
func build_classroom(n: String, c: Vector3, wall_color: Color) -> void:
	var x := c.x;  var z := c.z
	# Walls
	box(n+" Back",       Vector3(26, 5.0, 0.4), Vector3(x,      2.5, z-11), wall_color)
	box(n+" Left",       Vector3(0.4, 5.0, 22), Vector3(x-13,   2.5, z),    wall_color)
	box(n+" Right",      Vector3(0.4, 5.0, 22), Vector3(x+13,   2.5, z),    wall_color)
	box(n+" Front Left", Vector3(8,   5.0, 0.4), Vector3(x-8.5, 2.5, z+11), wall_color)
	box(n+" Front Right",Vector3(8,   5.0, 0.4), Vector3(x+8.5, 2.5, z+11), wall_color)
	# Doorframe
	box(n+" Door Frame T",Vector3(4.5, 0.5, 0.5), Vector3(x, 4.8, z+11), Color(0.55,0.52,0.45))
	box(n+" Door L",      Vector3(2.1, 4.5, 0.15), Vector3(x-1.1, 2.25, z+11.1), Color(0.60,0.40,0.18))
	box(n+" Door R",      Vector3(2.1, 4.5, 0.15), Vector3(x+1.1, 2.25, z+11.1), Color(0.60,0.40,0.18))
	# Whiteboard
	box(n+" Board",       Vector3(10, 2.2, 0.12), Vector3(x, 3.0, z-10.8), Color(0.92, 0.97, 0.92))
	box(n+" Board Tray",  Vector3(10, 0.2, 0.3),  Vector3(x, 1.95, z-10.8),Color(0.55, 0.55, 0.58))
	# Teacher desk
	box(n+" TDesk Top",   Vector3(5.5, 0.15, 2.2), Vector3(x, 0.95, z-7.5), Color(0.40,0.22,0.10))
	box(n+" TDesk Leg1",  Vector3(0.2, 0.95, 0.2), Vector3(x-2.5, 0.47, z-8.5), Color(0.30,0.15,0.07))
	box(n+" TDesk Leg2",  Vector3(0.2, 0.95, 0.2), Vector3(x+2.5, 0.47, z-8.5), Color(0.30,0.15,0.07))
	box(n+" TDesk Leg3",  Vector3(0.2, 0.95, 0.2), Vector3(x-2.5, 0.47, z-6.5), Color(0.30,0.15,0.07))
	box(n+" TDesk Leg4",  Vector3(0.2, 0.95, 0.2), Vector3(x+2.5, 0.47, z-6.5), Color(0.30,0.15,0.07))
	# Teacher chair
	box(n+" TChair Seat", Vector3(1.6, 0.15, 1.6), Vector3(x+3.5, 0.9, z-6.5), Color(0.18,0.18,0.22))
	box(n+" TChair Back", Vector3(1.6, 1.2, 0.15), Vector3(x+3.5, 1.5, z-7.2), Color(0.18,0.18,0.22))
	# Student desks (4 rows × 3 cols)
	for row in range(4):
		for col in range(3):
			var dx: float = x - 7.0 + col * 7.0
			var dz: float = z - 5.0 + row * 4.5
			box("SDesk Top",  Vector3(3.0, 0.12, 2.0), Vector3(dx, 0.78, dz),        Color(0.52,0.28,0.12))
			box("SDesk Leg1", Vector3(0.15,0.78,0.15), Vector3(dx-1.3,0.39,dz-0.8), Color(0.35,0.18,0.08))
			box("SDesk Leg2", Vector3(0.15,0.78,0.15), Vector3(dx+1.3,0.39,dz-0.8), Color(0.35,0.18,0.08))
			box("SDesk Leg3", Vector3(0.15,0.78,0.15), Vector3(dx-1.3,0.39,dz+0.8), Color(0.35,0.18,0.08))
			box("SDesk Leg4", Vector3(0.15,0.78,0.15), Vector3(dx+1.3,0.39,dz+0.8), Color(0.35,0.18,0.08))
			box("SChair",     Vector3(1.4, 0.12, 1.4), Vector3(dx, 0.52, dz+1.6),   Color(0.18,0.35,0.55))
	# Windows
	for w in range(3):
		box(n+" Window Frame", Vector3(3.5, 2.5, 0.18), Vector3(x-8+w*8, 2.8, z-11.0), Color(0.75,0.75,0.78))
		box(n+" Window Glass", Vector3(3.0, 2.1, 0.06), Vector3(x-8+w*8, 2.8, z-10.96),Color(0.55,0.75,0.90,0.4))
	# Bookshelf on side wall
	box(n+" Shelf Back", Vector3(0.12, 2.5, 5.0), Vector3(x-12.9, 2.0, z+2), Color(0.40,0.22,0.10))
	for shelf in range(4):
		box(n+" Shelf Board", Vector3(0.15, 0.12, 4.8), Vector3(x-12.82, 0.8+shelf*0.6, z+2), Color(0.50,0.28,0.12))
	# Floor mat
	box(n+" Mat", Vector3(24, 0.04, 20), Vector3(x, 0.02, z), Color(0.40,0.38,0.32))

# ══════════════════════════════════════════════
#  SCIENCE LAB
# ══════════════════════════════════════════════
func build_science_lab(c: Vector3) -> void:
	var x := c.x;  var z := c.z
	var wc := Color(0.50, 0.68, 0.60)
	box("Lab Back",       Vector3(26, 5.0, 0.4), Vector3(x,     2.5, z-11), wc)
	box("Lab Left",       Vector3(0.4, 5.0, 22), Vector3(x-13,  2.5, z),    wc)
	box("Lab Right",      Vector3(0.4, 5.0, 22), Vector3(x+13,  2.5, z),    wc)
	box("Lab Front L",    Vector3(8,   5.0, 0.4), Vector3(x-8.5,2.5, z+11), wc)
	box("Lab Front R",    Vector3(8,   5.0, 0.4), Vector3(x+8.5,2.5, z+11), wc)
	box("Lab Door L",     Vector3(2.1, 4.5, 0.15), Vector3(x-1.1,2.25,z+11.1), Color(0.60,0.40,0.18))
	box("Lab Door R",     Vector3(2.1, 4.5, 0.15), Vector3(x+1.1,2.25,z+11.1), Color(0.60,0.40,0.18))
	# Board
	box("Lab Board",      Vector3(10, 2.2, 0.12), Vector3(x, 3.0, z-10.8), Color(0.92,0.97,0.92))
	# Lab benches (island style)
	for i in range(3):
		var bz: float = z - 5.0 + i * 5.5
		box("Lab Bench Top",  Vector3(8.0, 0.15, 2.2), Vector3(x, 1.05, bz), Color(0.30,0.30,0.34))
		box("Lab Bench Body", Vector3(7.8, 1.0,  2.0), Vector3(x, 0.52, bz), Color(0.25,0.25,0.28))
		# Sink on first bench
		if i == 0:
			box("Lab Sink", Vector3(1.2, 0.1, 0.9), Vector3(x-2.5, 1.12, bz), Color(0.75,0.75,0.80))
			box("Lab Tap",  Vector3(0.08, 0.5, 0.08), Vector3(x-2.5, 1.4, bz-0.3), Color(0.70,0.70,0.72))
		# Beakers & equipment on bench
		for b in range(4):
			pickup("Beaker", Vector3(0.3, 0.5, 0.3), Vector3(x-3.0+b*2.0, 1.25, bz), Color(0.55,0.85,0.90), 0.3)
	# Chemical cabinet on back wall
	box("Chem Cabinet", Vector3(5, 3.5, 0.7), Vector3(x+9, 1.75, z-10.6), Color(0.28,0.35,0.28))
	for shelf in range(3):
		box("Chem Shelf", Vector3(4.6, 0.08, 0.5), Vector3(x+9, 0.7+shelf*1.1, z-10.3), Color(0.35,0.42,0.35))
	# Stools
	for row in range(3):
		for col in range(2):
			var sx: float = x - 2.5 + col * 5.0
			var sz: float = z - 5.0 + row * 5.5
			box("Stool Seat", Vector3(1.1,0.1,1.1), Vector3(sx, 0.8, sz+1.8), Color(0.15,0.15,0.18))
			box("Stool Leg1", Vector3(0.1,0.8,0.1), Vector3(sx-0.4,0.4,sz+1.4), Color(0.20,0.20,0.22))
			box("Stool Leg2", Vector3(0.1,0.8,0.1), Vector3(sx+0.4,0.4,sz+1.4), Color(0.20,0.20,0.22))
	# Floor tiles
	box("Lab Floor", Vector3(24, 0.04, 20), Vector3(x, 0.02, z), Color(0.38,0.38,0.40))

# ══════════════════════════════════════════════
#  POOL ROOM
# ══════════════════════════════════════════════
func build_pool_room(c: Vector3) -> void:
	var x := c.x;  var z := c.z
	var wc := Color(0.44, 0.58, 0.75)
	box("Pool Back",      Vector3(26, 5.0, 0.4), Vector3(x,     2.5, z-11), wc)
	box("Pool Left",      Vector3(0.4, 5.0, 22), Vector3(x-13,  2.5, z),    wc)
	box("Pool Right",     Vector3(0.4, 5.0, 22), Vector3(x+13,  2.5, z),    wc)
	box("Pool Front L",   Vector3(8,   5.0, 0.4), Vector3(x-8.5,2.5, z+11), wc)
	box("Pool Front R",   Vector3(8,   5.0, 0.4), Vector3(x+8.5,2.5, z+11), wc)
	box("Pool Door",      Vector3(4.0, 4.5, 0.15), Vector3(x,   2.25,z+11.1), Color(0.30,0.50,0.70))
	# Pool basin
	box("Pool Bottom",    Vector3(17, 0.3,  11), Vector3(x,  -0.85, z),    Color(0.25,0.55,0.80))
	box("Pool Wall Back", Vector3(17, 1.2, 0.3), Vector3(x,  0.3,  z-5.5),Color(0.82,0.84,0.88))
	box("Pool Wall Front",Vector3(17, 1.2, 0.3), Vector3(x,  0.3,  z+5.5),Color(0.82,0.84,0.88))
	box("Pool Wall Left", Vector3(0.3, 1.2, 11), Vector3(x-8.5,0.3, z),   Color(0.82,0.84,0.88))
	box("Pool Wall Right",Vector3(0.3, 1.2, 11), Vector3(x+8.5,0.3, z),   Color(0.82,0.84,0.88))
	# Water surface
	box("Pool Water",     Vector3(16.4, 0.1, 10.4), Vector3(x, 0.6, z),    Color(0.06, 0.42, 0.85))
	# Lane dividers
	for lane in range(4):
		box("Lane Rope", Vector3(0.1, 0.06, 10), Vector3(x-6+lane*4, 0.65, z), Color(0.95,0.20,0.10))
	# Pool deck tiles
	box("Pool Deck",      Vector3(24, 0.06, 20), Vector3(x, 0.02, z), Color(0.78,0.80,0.76))
	# Starting blocks
	for block in range(5):
		box("Start Block", Vector3(1.0,0.5,1.0), Vector3(x-8+block*4, 0.25, z-5.2), Color(0.65,0.18,0.10))
	# Benches
	for i in range(5):
		box("Pool Bench Seat", Vector3(3.0,0.2,1.0), Vector3(x-8+i*4, 0.5, z+8.0), Color(0.38,0.22,0.10))
		box("Pool Bench Leg1", Vector3(0.15,0.5,0.15), Vector3(x-9.3+i*4, 0.25,z+7.6), Color(0.25,0.15,0.08))
		box("Pool Bench Leg2", Vector3(0.15,0.5,0.15), Vector3(x-6.7+i*4, 0.25,z+7.6), Color(0.25,0.15,0.08))
	# Towel hooks on wall
	for h in range(8):
		box("Towel Hook", Vector3(0.1, 0.1, 0.3), Vector3(x-12.8, 1.5, z-8+h*2.3), Color(0.5,0.5,0.52))
	# Lifeguard chair
	box("LG Chair Seat",  Vector3(1.5, 0.15, 1.5), Vector3(x+11, 2.5, z),   Color(0.85,0.12,0.10))
	box("LG Chair Pole",  Vector3(0.2, 2.5, 0.2),  Vector3(x+11, 1.25, z),  Color(0.70,0.70,0.72))
	box("LG Chair Step1", Vector3(1.0, 0.15, 0.6), Vector3(x+11, 0.7, z+0.8), Color(0.65,0.65,0.68))
	box("LG Chair Step2", Vector3(1.0, 0.15, 0.6), Vector3(x+11, 1.3, z+0.5), Color(0.65,0.65,0.68))

# ══════════════════════════════════════════════
#  LIBRARY (center, back wing)
# ══════════════════════════════════════════════
func build_library(c: Vector3) -> void:
	var x := c.x;  var z := c.z
	var wc := Color(0.55, 0.50, 0.42)
	box("Lib Back",   Vector3(20, 5.0, 0.4), Vector3(x,    2.5, z-11), wc)
	box("Lib Left",   Vector3(0.4, 5.0, 22), Vector3(x-10, 2.5, z),   wc)
	box("Lib Right",  Vector3(0.4, 5.0, 22), Vector3(x+10, 2.5, z),   wc)
	box("Lib Front L",Vector3(6,   5.0, 0.4), Vector3(x-7, 2.5, z+11),wc)
	box("Lib Front R",Vector3(6,   5.0, 0.4), Vector3(x+7, 2.5, z+11),wc)
	box("Lib Door",   Vector3(3.5, 4.5, 0.15), Vector3(x, 2.25, z+11.1), Color(0.60,0.40,0.18))
	# Carpet
	box("Lib Carpet", Vector3(18, 0.06, 20), Vector3(x, 0.03, z), Color(0.42, 0.32, 0.55))
	# Bookshelves — 4 rows
	for row in range(4):
		for side in [-1, 1]:
			var bx: float = x + side * 5.5
			var bz: float = z - 8.0 + row * 5.0
			box("Lib Shelf Back", Vector3(0.2, 3.5, 4.5), Vector3(bx, 1.75, bz), Color(0.38,0.20,0.08))
			for shelf in range(5):
				box("Lib Shelf Board", Vector3(0.22, 0.1, 4.3), Vector3(bx, 0.4+shelf*0.62, bz), Color(0.46,0.26,0.10))
			# Books on shelves (color blocks)
			for b in range(7):
				pickup("LBook", Vector3(0.18,0.5,0.55), Vector3(bx+(side*0.1), 0.75+int(float(b)/3.0)*0.65, bz-1.5+b*0.55),
					Color(randf_range(0.4,0.9), randf_range(0.1,0.6), randf_range(0.1,0.5)), 0.5)
	# Reading tables
	for t in range(2):
		var tx: float = x - 1.5 + t * 3.0
		box("Read Table Top",  Vector3(3.0, 0.12, 1.8), Vector3(tx, 0.78, z+4), Color(0.42,0.22,0.10))
		box("Read Table Leg1", Vector3(0.12,0.78,0.12), Vector3(tx-1.3,0.39,z+3.2), Color(0.30,0.15,0.07))
		box("Read Table Leg2", Vector3(0.12,0.78,0.12), Vector3(tx+1.3,0.39,z+3.2), Color(0.30,0.15,0.07))
		box("Read Table Leg3", Vector3(0.12,0.78,0.12), Vector3(tx-1.3,0.39,z+4.8), Color(0.30,0.15,0.07))
		box("Read Table Leg4", Vector3(0.12,0.78,0.12), Vector3(tx+1.3,0.39,z+4.8), Color(0.30,0.15,0.07))
		box("Read Chair",      Vector3(1.3, 0.1, 1.3), Vector3(tx, 0.52, z+6.0), Color(0.30,0.18,0.50))
	# Librarian desk
	box("Lib Desk Top",  Vector3(4.5, 0.15, 2.0), Vector3(x, 1.05, z-8.0), Color(0.38,0.20,0.08))
	box("Lib Desk Front",Vector3(4.5, 1.0,  0.3), Vector3(x, 0.5,  z-7.1), Color(0.46,0.26,0.10))
	# Computer on desk
	box("PC Monitor",  Vector3(1.4, 1.0, 0.1), Vector3(x+1.0, 1.65, z-8.2), Color(0.12,0.12,0.14))
	box("PC Screen",   Vector3(1.2, 0.85, 0.06), Vector3(x+1.0, 1.65, z-8.14), Color(0.10,0.30,0.55))
	box("PC Base",     Vector3(0.5, 0.1,  0.4), Vector3(x+1.0, 1.18, z-8.2), Color(0.20,0.20,0.22))
	# Globe
	box("Globe Stand", Vector3(0.1, 0.5, 0.1), Vector3(x-1.5, 0.8, z-8.5), Color(0.35,0.22,0.10))
	box("Globe Ball",  Vector3(0.7, 0.7, 0.7), Vector3(x-1.5, 1.3, z-8.5), Color(0.20,0.45,0.72))

# ══════════════════════════════════════════════
#  CAFETERIA (center, front wing)
# ══════════════════════════════════════════════
func build_cafeteria(c: Vector3) -> void:
	var x := c.x;  var z := c.z
	var wc := Color(0.65, 0.62, 0.50)
	box("Caf Back",   Vector3(20, 5.0, 0.4), Vector3(x,    2.5, z-11), wc)
	box("Caf Left",   Vector3(0.4, 5.0, 22), Vector3(x-10, 2.5, z),   wc)
	box("Caf Right",  Vector3(0.4, 5.0, 22), Vector3(x+10, 2.5, z),   wc)
	box("Caf Front L",Vector3(5,   5.0, 0.4), Vector3(x-7.5,2.5,z+11),wc)
	box("Caf Front R",Vector3(5,   5.0, 0.4), Vector3(x+7.5,2.5,z+11),wc)
	box("Caf Door L", Vector3(2.1, 4.5, 0.15), Vector3(x-1.1,2.25,z+11.1), Color(0.60,0.50,0.28))
	box("Caf Door R", Vector3(2.1, 4.5, 0.15), Vector3(x+1.1,2.25,z+11.1), Color(0.60,0.50,0.28))
	# Floor tiles
	box("Caf Floor",  Vector3(18, 0.06, 20), Vector3(x, 0.03, z), Color(0.68,0.65,0.55))
	# Long dining tables (3 rows)
	for row in range(3):
		var tz: float = z - 6.0 + row * 5.5
		box("Caf Table Top",  Vector3(14, 0.15, 2.2), Vector3(x, 0.78, tz),        Color(0.85,0.78,0.55))
		box("Caf Table Leg1", Vector3(0.2, 0.78, 0.2), Vector3(x-6.5,0.39,tz-0.9), Color(0.55,0.48,0.35))
		box("Caf Table Leg2", Vector3(0.2, 0.78, 0.2), Vector3(x+6.5,0.39,tz-0.9), Color(0.55,0.48,0.35))
		box("Caf Table Leg3", Vector3(0.2, 0.78, 0.2), Vector3(x-6.5,0.39,tz+0.9), Color(0.55,0.48,0.35))
		box("Caf Table Leg4", Vector3(0.2, 0.78, 0.2), Vector3(x+6.5,0.39,tz+0.9), Color(0.55,0.48,0.35))
		# Chairs both sides
		for col in range(6):
			box("Caf Chair F", Vector3(1.2,0.1,1.2), Vector3(x-6+col*2.4, 0.5, tz+1.8), Color(0.22,0.38,0.18))
			box("Caf Chair B", Vector3(1.2,0.1,1.2), Vector3(x-6+col*2.4, 0.5, tz-1.8), Color(0.22,0.38,0.18))
		# Food trays on table
		for t in range(5):
			pickup("Tray", Vector3(1.4,0.06,1.0), Vector3(x-5+t*2.5, 0.87, tz), Color(0.70,0.45,0.18), 0.5)
	# Food counter / service area on back wall
	box("Counter Base", Vector3(14, 1.2, 1.8), Vector3(x, 0.6, z-9.0), Color(0.55,0.52,0.45))
	box("Counter Top",  Vector3(14, 0.1, 1.8), Vector3(x, 1.25, z-9.0), Color(0.78,0.76,0.68))
	box("Counter Glass",Vector3(12, 0.8, 0.1), Vector3(x, 1.7, z-8.15), Color(0.55,0.78,0.90))
	# Food items on counter
	for f in range(5):
		box("Food Tray", Vector3(1.5,0.3,1.2), Vector3(x-5+f*2.5, 1.4, z-9.2), Color(0.80,0.55+f*0.04,0.20))
	# Cash register
	box("Cash Reg", Vector3(0.8,0.5,0.5), Vector3(x+6.5, 1.5, z-8.2), Color(0.15,0.15,0.18))

# ══════════════════════════════════════════════
#  BATHROOMS
# ══════════════════════════════════════════════
func build_bathrooms() -> void:
	for side in [-1, 1]:
		var x: float = side * 50.0
		var z: float = 0.0
		var label := "Bath L" if side < 0 else "Bath R"
		var wc := Color(0.70, 0.70, 0.72)
		box(label+" Back",   Vector3(10, 5.0, 0.4), Vector3(x,   2.5, z-7),  wc)
		box(label+" Left",   Vector3(0.4, 5.0, 14), Vector3(x-5, 2.5, z),    wc)
		box(label+" Right",  Vector3(0.4, 5.0, 14), Vector3(x+5, 2.5, z),    wc)
		box(label+" Front L",Vector3(3,   5.0, 0.4), Vector3(x-3.5,2.5,z+7), wc)
		box(label+" Front R",Vector3(3,   5.0, 0.4), Vector3(x+3.5,2.5,z+7), wc)
		box(label+" Door",   Vector3(3.5, 4.5, 0.15), Vector3(x, 2.25, z+7.1), Color(0.60,0.60,0.62))
		# Tiles floor
		box(label+" Floor",  Vector3(9, 0.06, 13), Vector3(x, 0.03, z), Color(0.75,0.75,0.78))
		# Stalls
		for st in range(2):
			var stx: float = x - 2.0 + st * 4.0
			box(label+" Stall Back",  Vector3(2.2, 3.0, 0.12), Vector3(stx, 1.5, z-6.5), Color(0.65,0.65,0.68))
			box(label+" Stall Side1", Vector3(0.12,3.0, 2.4), Vector3(stx-1.1,1.5,z-5.4), Color(0.65,0.65,0.68))
			box(label+" Stall Side2", Vector3(0.12,3.0, 2.4), Vector3(stx+1.1,1.5,z-5.4), Color(0.65,0.65,0.68))
			box(label+" Stall Door",  Vector3(1.9, 2.6, 0.1), Vector3(stx, 1.8, z-4.3), Color(0.55,0.55,0.58))
		# Sinks
		for s in range(3):
			box(label+" Sink Base",  Vector3(0.9,0.9,0.5), Vector3(x-2+s*2.0, 0.55, z+4.5), Color(0.72,0.72,0.75))
			box(label+" Sink Bowl",  Vector3(0.7,0.1,0.4), Vector3(x-2+s*2.0, 1.05, z+4.5), Color(0.85,0.85,0.88))
			box(label+" Sink Tap",   Vector3(0.06,0.3,0.06),Vector3(x-2+s*2.0,1.2,z+4.3),   Color(0.65,0.65,0.68))
		# Mirror above sinks
		box(label+" Mirror", Vector3(5.5, 1.5, 0.08), Vector3(x, 1.8, z+5.15), Color(0.70,0.80,0.90))

# ══════════════════════════════════════════════
#  STAIRCASE
# ══════════════════════════════════════════════
func build_staircase(c: Vector3) -> void:
	var x := c.x;  var z := c.z
	for step in range(10):
		box("Stair Step", Vector3(6.0, 0.3, 1.2),
			Vector3(x, 0.15 + step * 0.6, z - 4 + step * 1.2),
			Color(0.45, 0.42, 0.38))
	# Railing
	for r in range(11):
		box("Rail Post", Vector3(0.1, 1.0 + r*0.06, 0.1),
			Vector3(x + 3.1, 0.5 + r * 0.6, z - 4 + r * 1.2),
			Color(0.55, 0.55, 0.58))
	box("Rail Bar",  Vector3(0.1, 0.1, 14), Vector3(x+3.1, 7.0, z+2), Color(0.55,0.55,0.58))
	# Mirror staircase right side
	for step in range(10):
		box("Stair Step R", Vector3(6.0, 0.3, 1.2),
			Vector3(-x, 0.15 + step * 0.6, z - 4 + step * 1.2),
			Color(0.45, 0.42, 0.38))
	box("Rail Bar R", Vector3(0.1, 0.1, 14), Vector3(-x-3.1, 7.0, z+2), Color(0.55,0.55,0.58))

# ══════════════════════════════════════════════
#  SECOND FLOOR (basic shell + hallway)
# ══════════════════════════════════════════════
func build_second_floor() -> void:
	box("Floor2 Slab",    Vector3(130, 0.4, 100), Vector3(0, 5.8, 0),  Color(0.28,0.28,0.32))
	box("Ceiling2",       Vector3(130, 0.4, 100), Vector3(0, 12.0, 0), Color(0.14,0.14,0.17))
	box("Wall2 Back",     Vector3(130, 6.4, 0.5), Vector3(0,  9.0,-50), Color(0.62,0.59,0.52))
	box("Wall2 Front",    Vector3(130, 6.4, 0.5), Vector3(0,  9.0, 50), Color(0.62,0.59,0.52))
	box("Wall2 Left",     Vector3(0.5, 6.4, 100), Vector3(-65, 9.0, 0), Color(0.62,0.59,0.52))
	box("Wall2 Right",    Vector3(0.5, 6.4, 100), Vector3( 65, 9.0, 0), Color(0.62,0.59,0.52))
	box("Hall2 Wall L",   Vector3(0.4, 5.0, 88),  Vector3(-10, 8.5, 0), Color(0.50,0.50,0.55))
	box("Hall2 Wall R",   Vector3(0.4, 5.0, 88),  Vector3( 10, 8.5, 0), Color(0.50,0.50,0.55))
	# 2nd floor rooms (art room + computer lab + more classrooms)
	build_classroom("Art Room",    Vector3(-34, 6, -22), Color(0.75, 0.62, 0.50))
	build_classroom("Comp Lab",    Vector3( 34, 6, -22), Color(0.40, 0.52, 0.68))
	build_classroom("Classroom C", Vector3(-34, 6,  20), Color(0.72, 0.68, 0.55))
	build_classroom("Classroom D", Vector3( 34, 6,  20), Color(0.72, 0.68, 0.55))
	# 2nd floor lockers
	for i in range(18):
		var z := -42.0 + i * 5.0
		box("Locker2 L", Vector3(0.7,3.2,1.1), Vector3(-9.3, 7.6, z), Color(0.28,0.14,0.08))
		box("Locker2 R", Vector3(0.7,3.2,1.1), Vector3( 9.3, 7.6, z), Color(0.28,0.14,0.08))

# ══════════════════════════════════════════════
#  LIGHTING
# ══════════════════════════════════════════════
func add_lights() -> void:
	# Ambient
	var env_light := DirectionalLight3D.new()
	env_light.name = "SunLight"
	env_light.light_energy = 0.6
	env_light.rotation_degrees = Vector3(-45, 30, 0)
	env_light.shadow_enabled = true
	add_child(env_light)

	# Hallway ceiling lights (floor 1)
	for i in range(10):
		var z := -40.0 + i * 9.0
		_omni(Vector3(0, 5.5, z), 12.0, 1.2, Color(1.0, 0.98, 0.90))

	# Room lights
	for rx in [-34.0, 34.0, 0.0]:
		for rz in [-22.0, 20.0]:
			_omni(Vector3(rx, 5.2, rz), 14.0, 1.4, Color(1.0, 0.97, 0.88))

	# Second floor hallway
	for i in range(10):
		var z := -40.0 + i * 9.0
		_omni(Vector3(0, 11.5, z), 12.0, 1.2, Color(1.0, 0.98, 0.90))

func _omni(pos: Vector3, rng: float, energy: float, col: Color) -> void:
	var light := OmniLight3D.new()
	light.name = "OmniLight"
	light.position = pos
	light.omni_range = rng
	light.light_energy = energy
	light.light_color = col
	add_child(light)
	# Fixture box
	box("Light Fix", Vector3(0.8, 0.15, 0.8), pos + Vector3(0, 0.1, 0), Color(0.9, 0.9, 0.85))

# ══════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════
func box(n: String, size: Vector3, pos: Vector3, col: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = n

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.85
	mat.metallic = 0.0
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col_shape.shape = box_shape
	body.add_child(col_shape)

	body.position = pos
	add_child(body)
	return body

func pickup(n: String, size: Vector3, pos: Vector3, col: Color, _mass: float) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = n

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.9
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col_shape.shape = box_shape
	body.add_child(col_shape)

	body.position = pos
	body.mass = _mass
	add_child(body)
	return body
