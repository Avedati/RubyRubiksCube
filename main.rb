# https://github.com/gosu/gosu-examples/blob/master/examples/chipmunk_and_rmagick.rb
require "gosu"

WINDOW_WIDTH = 840
WINDOW_HEIGHT = 680

class Vec3
	def initialize(x, y, z)
		@x = x
		@y = y
		@z = z
	end

	def x; @x end
	def x=(x); @x=x end
	def y; @y end
	def y=(y); @y=y end
	def z; @z end
	def z=(z); @z=z end

	def +(other); Vec3.new(@x + other.x, @y + other.y, @z + other.z) end
	def -(other); Vec3.new(@x - other.x, @y - other.y, @z - other.z) end
	def *(other); Vec3.new(@x * other, @y * other, @z * other) end
	def coerce(other); [self, other] end
	def rotate3d(angles)
		origX = @x; origY = @y; origZ = @z

		temp1 = @z * Math.cos(angles.x) - @y * Math.sin(angles.x)
		temp2 = @z * Math.sin(angles.x) + @y * Math.cos(angles.x)
		@z = temp1; @y = temp2

		temp1 = @x * Math.cos(angles.y) - @z * Math.sin(angles.y)
		temp2 = @x * Math.sin(angles.y) + @z * Math.cos(angles.y)
		@x = temp1; @z = temp2

		temp1 = @x * Math.cos(angles.z) - @y * Math.sin(angles.z)
		temp2 = @x * Math.sin(angles.z) + @y * Math.cos(angles.z)
		@x = temp1; @y = temp2

		result = Vec3.new(@x, @y, @z)
		@x = origX; @y = origY; @z = origZ
		result
	end
end

class Camera
	def initialize(pos, rot)
		@pos = pos
		@rot = rot
	end

	def pos; @pos end
	def pos=(pos); @pos = pos end
	def rot; @rot end
	def rot=(rot); @rot = rot end
end

class Cube
	def initialize(pos, rot, colors)
		@pos = pos
		@rot = rot
		@colors = colors
		@points = [
			Vec3.new(-0.5, -0.5, -0.5),
			Vec3.new( 0.5, -0.5, -0.5),
			Vec3.new( 0.5,  0.5, -0.5),
			Vec3.new(-0.5,  0.5, -0.5),
			Vec3.new(-0.5, -0.5,  0.5),
			Vec3.new( 0.5, -0.5,  0.5),
			Vec3.new( 0.5,  0.5,  0.5),
			Vec3.new(-0.5,  0.5,  0.5)
		]
		@lines = [
			[0, 1], [1, 2], [2, 3], [3, 0],
			[4, 5], [5, 6], [6, 7], [7, 4],
			[0, 4], [1, 5], [2, 6], [3, 7]
		]
		@faces = [
			[0, 1, 2, 3],
			[4, 5, 6, 7],
			[0, 1, 5, 4],
			[3, 2, 6, 7],
			[0, 3, 7, 4],
			[1, 2, 6, 5]
		]
	end

	def rot; @rot end

	# Order of sides: front, back, top, bottom, left, right
	def front; @colors[0] end
	def front=(front); @colors[0] = front end
	def back; @colors[1] end
	def back=(back); @colors[1] = back end
	def top; @colors[2] end
	def top=(top); @colors[2] = top end
	def bottom; @colors[3] end
	def bottom=(bottom); @colors[3] = bottom end
	def left; @colors[4] end
	def left=(left); @colors[4] = left end
	def right; @colors[5] end
	def right=(right); @colors[5] = right end

	def access(mode)
		case mode
			when 'front'
				self.front
			when 'back'
				self.back
			when 'top'
				self.top
			when 'bottom'
				self.bottom
			when 'left'
				self.left
			when 'right'
				self.right
		end
	end

	def set(mode, arg)
		case mode
			when 'front'
				self.front= arg
			when 'back'
				self.back= arg
			when 'top'
				self.top= arg
			when 'bottom'
				self.bottom= arg
			when 'left'
				self.left= arg
			when 'right'
				self.right= arg
		end
	end

	def project(camera)
		@points.map { |pt|
			pt = (pt + @pos).rotate3d(@rot).rotate3d(camera.rot) - camera.pos
			f = (WINDOW_WIDTH + WINDOW_HEIGHT) / (2 * pt.z)
			x = WINDOW_WIDTH / 2 + pt.x * f
			y = WINDOW_HEIGHT / 2 + pt.y * f
			Vec3.new(x, y, pt.z)
		}
	end

	def update(window, camera); end

	def score(point); (point.x - WINDOW_WIDTH / 2) * (2 * point.z) / (WINDOW_WIDTH + WINDOW_HEIGHT)**2 + (point.y - WINDOW_HEIGHT / 2) * (2 * point.z) / (WINDOW_WIDTH + WINDOW_HEIGHT)**2 + point.z**2 end

	# https://stackoverflow.com/questions/1538789/how-to-sum-array-of-numbers-in-ruby 
	def score_total(camera); self.project(camera).inject(0) { |score, current| score + self.score(current) } end

	def draw(window, camera)
		projected = self.project(camera)
		#projected.each { |pt| window.draw_rect(pt.x - 1, pt.y - 1, 2, 2, Gosu::Color.argb(0xff_ffffff)) }
		@lines.each { |line| window.draw_line(projected[line[0]].x, projected[line[0]].y, Gosu::Color.argb(0xff_000000), projected[line[1]].x, projected[line[1]].y, Gosu::Color.argb(0xff_000000)) }
		scores = @faces.map { |face| face.inject(0) { |score, index| score + self.score(projected[index]) } }
		(0..(@faces.length-1)).to_a.sort { |a,b| scores[b] <=> scores[a] }.each { |index|
			window.draw_quad(
				projected[@faces[index][0]].x, projected[@faces[index][0]].y, @colors[index],
				projected[@faces[index][1]].x, projected[@faces[index][1]].y, @colors[index],
				projected[@faces[index][2]].x, projected[@faces[index][2]].y, @colors[index],
				projected[@faces[index][3]].x, projected[@faces[index][3]].y, @colors[index]
			)
		}
	end
end

class Window < Gosu::Window
	def initialize
		super WINDOW_WIDTH, WINDOW_HEIGHT
		self.caption = "Rubik\'s Cube -- version 0.1"
		@camera = Camera.new(Vec3.new(0, 0, -15), Vec3.new(0, 0, 0))
		# x-axis: -1 is left, 1 is right
		# y-axis: -1 is up, 1 is down
		# z-axis: -1 is forward, 1 is backward
		# Order of sides: front, back, top, bottom, left, right
		@cubes = [
			Cube.new(Vec3.new(-1, -1, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, -1, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, -1, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),
			Cube.new(Vec3.new(-1, 0, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, 0, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, 0, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),
			Cube.new(Vec3.new(-1, 1, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, 1, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, 1, -1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_ffffff),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),

			Cube.new(Vec3.new(-1, -1, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, -1, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, -1, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),
			Cube.new(Vec3.new(-1, 0, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),

			Cube.new(Vec3.new(1, 0, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),
			Cube.new(Vec3.new(-1, 1, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, 1, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, 1, 0), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),

			Cube.new(Vec3.new(-1, -1, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, -1, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, -1, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_ff0000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),
			Cube.new(Vec3.new(-1, 0, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, 0, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, 0, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),
			Cube.new(Vec3.new(-1, 1, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_0000ff),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(0, 1, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_000000)
			]),
			Cube.new(Vec3.new(1, 1, 1), Vec3.new(0, 0, 0), [
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ffff00),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_ff8800),
				Gosu::Color.argb(0xff_000000),
				Gosu::Color.argb(0xff_00ff00)
			]),
		]

		@animation = {
			:function => nil,
			:resetFunction => nil,
			:frame => 0,
			:maxFrames => 30
		}

		@scramble = {
			:active? => false,
			:count => 0,
			:max => 30
		}
	end

	def needs_cursor?
		true
	end

	def generic_reset
		@cubes.each { |cube| cube.rot.x = 0; cube.rot.y = 0; cube.rot.z = 0 }
		@animation[:function] = nil
		@animation[:resetFunction] = nil
		@animation[:frame] = 0
	end

	def generic_turn(indices, sides)
		temp = @cubes[indices[0]].access(sides[0])
		@cubes[indices[0]].set(sides[0], @cubes[indices[6]].access(sides[0]))
		@cubes[indices[6]].set(sides[0], @cubes[indices[8]].access(sides[0]))
		@cubes[indices[8]].set(sides[0], @cubes[indices[2]].access(sides[0]))
		@cubes[indices[2]].set(sides[0], temp)
		temp = @cubes[indices[1]].access(sides[0])
		@cubes[indices[1]].set(sides[0], @cubes[indices[3]].access(sides[0]))
		@cubes[indices[3]].set(sides[0], @cubes[indices[7]].access(sides[0]))
		@cubes[indices[7]].set(sides[0], @cubes[indices[5]].access(sides[0]))
		@cubes[indices[5]].set(sides[0], temp)
		temp0 = @cubes[indices[0]].access(sides[1])
		temp1 = @cubes[indices[1]].access(sides[1])
		temp2 = @cubes[indices[2]].access(sides[1])
		@cubes[indices[0]].set(sides[1], @cubes[indices[6]].access(sides[2]))
		@cubes[indices[1]].set(sides[1], @cubes[indices[3]].access(sides[2]))
		@cubes[indices[2]].set(sides[1], @cubes[indices[0]].access(sides[2]))
		@cubes[indices[6]].set(sides[2], @cubes[indices[8]].access(sides[3]))
		@cubes[indices[3]].set(sides[2], @cubes[indices[7]].access(sides[3]))
		@cubes[indices[0]].set(sides[2], @cubes[indices[6]].access(sides[3]))
		@cubes[indices[8]].set(sides[3], @cubes[indices[2]].access(sides[4]))
		@cubes[indices[7]].set(sides[3], @cubes[indices[5]].access(sides[4]))
		@cubes[indices[6]].set(sides[3], @cubes[indices[8]].access(sides[4]))
		@cubes[indices[2]].set(sides[4], temp0)
		@cubes[indices[5]].set(sides[4], temp1)
		@cubes[indices[8]].set(sides[4], temp2)
	end

	def f(prime)
		if prime
			@cubes[0,9].each { |cube| cube.rot.z -= Math::PI / (2 * @animation[:maxFrames]) }
		else
			@cubes[0,9].each { |cube| cube.rot.z += Math::PI / (2 * @animation[:maxFrames]) }
		end
	end

	def f_reset(iterations)
		self.generic_reset
		for _ in 0..(iterations-1)
			self.generic_turn((0..8).to_a, ['front', 'top', 'left', 'bottom', 'right'])
		end
	end	

	def b(prime)
		if prime
			@cubes[17,26].each { |cube| cube.rot.z += Math::PI / (2 * @animation[:maxFrames]) }
		else
			@cubes[17,26].each { |cube| cube.rot.z -= Math::PI / (2 * @animation[:maxFrames]) }
		end
	end

	def b_reset(iterations)
		self.generic_reset
		for _ in 0..(iterations-1)
			self.generic_turn([19, 18, 17, 22, 21, 20, 25, 24, 23], ['back', 'top', 'right', 'bottom', 'left'])
		end
	end

	def u(prime)
		if prime
			[0, 1, 2, 9, 10, 11, 17, 18, 19].map { |index| @cubes[index].rot.y += Math::PI / (2 * @animation[:maxFrames]) }
		else
			[0, 1, 2, 9, 10, 11, 17, 18, 19].map { |index| @cubes[index].rot.y -= Math::PI / (2 * @animation[:maxFrames]) }
		end
	end

	def u_reset(iterations)
		self.generic_reset
		for _ in 0..(iterations-1)
			self.generic_turn([17, 18, 19, 9, 10, 11, 0, 1, 2], ['top', 'back', 'left', 'front', 'right'])
		end
	end

	def d(prime)
		if prime
			[6, 7, 8, 14, 15, 16, 23, 24, 25].map { |index| @cubes[index].rot.y -= Math::PI / (2 * @animation[:maxFrames]) }
		else
			[6, 7, 8, 14, 15, 16, 23, 24, 25].map { |index| @cubes[index].rot.y += Math::PI / (2 * @animation[:maxFrames]) }
		end
	end

	def d_reset(iterations)
		self.generic_reset
		for _ in 0..(iterations-1)
			self.generic_turn([6, 7, 8, 14, 15, 16, 23, 24, 25], ['bottom', 'front', 'left', 'back', 'right'])
		end
	end

	def l(prime)
		if prime
			[17, 9, 0, 20, 12, 3, 23, 14, 6].map { |index| @cubes[index].rot.x += Math::PI / (2 * @animation[:maxFrames]) }
		else
			[17, 9, 0, 20, 12, 3, 23, 14, 6].map { |index| @cubes[index].rot.x -= Math::PI / (2 * @animation[:maxFrames]) }
		end
	end

	def l_reset(iterations)
		self.generic_reset
		for _ in 0..(iterations-1)
			self.generic_turn([17, 9, 0, 20, 12, 3, 23, 14, 6], ['left', 'top', 'back', 'bottom', 'front'])
		end
	end

	def r(prime)
		if prime
			[2, 11, 19, 5, 13, 22, 8, 16, 25].map { |index| @cubes[index].rot.x -= Math::PI / (2 * @animation[:maxFrames]) }
		else
			[2, 11, 19, 5, 13, 22, 8, 16, 25].map { |index| @cubes[index].rot.x += Math::PI / (2 * @animation[:maxFrames]) }
		end
	end

	def r_reset(iterations)
		self.generic_reset
		for _ in 0..(iterations-1)
			self.generic_turn([2, 11, 19, 5, 13, 22, 8, 16, 25], ['right', 'top', 'front', 'bottom', 'back'])
		end
	end

	def scramble
		@animation[:maxFrames] = 10
		choice = (rand * 12).floor
		case choice
			when 0
				@animation[:function] = lambda { self.f(false) }
				@animation[:resetFunction] = lambda { self.f_reset(1) }
			when 1
				@animation[:function] = lambda { self.f(true) }
				@animation[:resetFunction] = lambda { self.f_reset(3) }
			when 2
				@animation[:function] = lambda { self.b(false) }
				@animation[:resetFunction] = lambda { self.b_reset(1) }
			when 3
				@animation[:function] = lambda { self.b(true) }
				@animation[:resetFunction] = lambda { self.b_reset(3) }
			when 4 
				@animation[:function] = lambda { self.u(false) }
				@animation[:resetFunction] = lambda { self.u_reset(1) }
			when 5
				@animation[:function] = lambda { self.u(true) }
				@animation[:resetFunction] = lambda { self.u_reset(3) }
			when 6
				@animation[:function] = lambda { self.d(false) }
				@animation[:resetFunction] = lambda { self.d_reset(1) }
			when 7
				@animation[:function] = lambda { self.d(true) }
				@animation[:resetFunction] = lambda { self.d_reset(3) }
			when 8
				@animation[:function] = lambda { self.l(false) }
				@animation[:resetFunction] = lambda { self.l_reset(1) }
			when 9
				@animation[:function] = lambda { self.l(true) }
				@animation[:resetFunction] = lambda { self.l_reset(3) }
			when 10
				@animation[:function] = lambda { self.r(false) }
				@animation[:resetFunction] = lambda { self.r_reset(1) }
			when 11
				@animation[:function] = lambda { self.r(true) }
				@animation[:resetFunction] = lambda { self.r_reset(3) }
		end
	end

	def update
		if Gosu.button_down? Gosu::KB_LEFT
			@camera.rot.y -= 0.1
		end
		if Gosu.button_down? Gosu::KB_RIGHT
			@camera.rot.y += 0.1
		end
		if Gosu.button_down? Gosu::KB_UP
			@camera.rot.x += 0.1
		end
		if Gosu.button_down? Gosu::KB_DOWN
			@camera.rot.x -= 0.1
		end
		if Gosu.button_down? Gosu::MS_LEFT
			x = (self.mouse_x - WINDOW_WIDTH / 2) * 2.0 / WINDOW_WIDTH
			y = (self.mouse_y - WINDOW_HEIGHT / 2) * 2.0 / WINDOW_HEIGHT
			@camera.rot.y = -x * Math::PI
			@camera.rot.x = y * Math::PI
		end
		if Gosu.button_down? Gosu::KB_F and @animation[:function] == nil
			# https://scoutapm.com/blog/how-to-use-lambdas-in-ruby
			prime = (Gosu.button_down? Gosu::KB_LEFT_SHIFT) or (Gosu.button_down? Gosu::KB_RIGHT_SHIFT)
			@animation[:function] = lambda { self.f(prime) }
			@animation[:resetFunction] = lambda { self.f_reset(prime ? 3 : 1) }
		end
		if Gosu.button_down? Gosu::KB_B and @animation[:function] == nil
			# https://scoutapm.com/blog/how-to-use-lambdas-in-ruby
			prime = (Gosu.button_down? Gosu::KB_LEFT_SHIFT) or (Gosu.button_down? Gosu::KB_RIGHT_SHIFT)
			@animation[:function] = lambda { self.b(prime) }
			@animation[:resetFunction] = lambda { self.b_reset(prime ? 3 : 1) }
		end
		if Gosu.button_down? Gosu::KB_U and @animation[:function] == nil
			# https://scoutapm.com/blog/how-to-use-lambdas-in-ruby
			prime = (Gosu.button_down? Gosu::KB_LEFT_SHIFT) or (Gosu.button_down? Gosu::KB_RIGHT_SHIFT)
			@animation[:function] = lambda { self.u(prime) }
			@animation[:resetFunction] = lambda { self.u_reset(prime ? 3 : 1) }
		end
		if Gosu.button_down? Gosu::KB_D and @animation[:function] == nil
			# https://scoutapm.com/blog/how-to-use-lambdas-in-ruby
			prime = (Gosu.button_down? Gosu::KB_LEFT_SHIFT) or (Gosu.button_down? Gosu::KB_RIGHT_SHIFT)
			@animation[:function] = lambda { self.d(prime) }
			@animation[:resetFunction] = lambda { self.d_reset(prime ? 3 : 1) }
		end
		if Gosu.button_down? Gosu::KB_L and @animation[:function] == nil
			# https://scoutapm.com/blog/how-to-use-lambdas-in-ruby
			prime = (Gosu.button_down? Gosu::KB_LEFT_SHIFT) or (Gosu.button_down? Gosu::KB_RIGHT_SHIFT)
			@animation[:function] = lambda { self.l(prime) }
			@animation[:resetFunction] = lambda { self.l_reset(prime ? 3 : 1) }
		end
		if Gosu.button_down? Gosu::KB_R and @animation[:function] == nil
			# https://scoutapm.com/blog/how-to-use-lambdas-in-ruby
			prime = (Gosu.button_down? Gosu::KB_LEFT_SHIFT) or (Gosu.button_down? Gosu::KB_RIGHT_SHIFT)
			@animation[:function] = lambda { self.r(prime) }
			@animation[:resetFunction] = lambda { self.r_reset(prime ? 3 : 1) }
		end
		if Gosu.button_down? Gosu::KB_SPACE
			@scramble[:active?] = true
			self.scramble
		end
		if @animation[:function] != nil
			@animation[:function].call
			@animation[:frame] += 1
			if @animation[:frame] == @animation[:maxFrames]
				@animation[:resetFunction].call
				if @scramble[:active?]
					@scramble[:count] += 1
					if @scramble[:count] == @scramble[:max]
						@scramble[:active?] = false
						@scramble[:count] = 0
						@animation[:maxFrames] = 30
					else
						self.scramble
					end
				end
			end
		end
		@cubes.each { |cube| cube.update(self, @camera) }
	end

	def draw
		self.draw_rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, Gosu::Color.argb(0xff_000000))
		scores = @cubes.map { |cube| cube.score_total(@camera) }
		(0..(@cubes.length-1)).to_a.sort { |a,b| scores[b] <=> scores[a] }.each { |index| @cubes[index].draw(self, @camera) }
	end
end

Window.new.show if __FILE__ == $0
