extends CharacterBody2D

const SPEED = 240.0
const WALL_JUMP_VELOCITY = -180.0
const MOVE_ACCEL = 0.10
const STOP_ACCEL = 0.10
var jump_timer = 0.0
var jump_velocity = 0.0
var coyote_timer = 0.0
var jump_in_progress = false
enum DIRECTION {right, left}
var can_attack = true
var can_block = true
var device = ""
var last_direction = DIRECTION.right
var move = false
var atk = false
var blk = false
var health = 120
var taken_damage = false
var is_blocking = false
func _ready():
	# CHANGE WHICH INPUT DEVICE TO USE
	match name:
		"Player":
			device = "Keyboard0_"
		"Player2":
			device = "Keyboard1_"

func _physics_process(delta: float) -> void:
	# PHYSICS
	if device != "":
		if is_on_floor():
			coyote_timer = 0.0
			jump_in_progress = false
		if not is_on_floor():
			velocity += get_gravity() * delta
			coyote_timer += delta
		if not Input.is_action_pressed(device+"Jump"):
			jump_timer = 0.01
			jump_velocity = 0.0
		if jump_timer != 0.01: # If you press jump, jump timer increases. It is 0.01 by default
			if is_on_wall_only():
				velocity.y = WALL_JUMP_VELOCITY
			elif jump_timer < 0.11:
				jump_velocity = -18
				if velocity.y > 0.0:
					velocity.y = 0.0
				velocity.y += jump_velocity*(0.55/(jump_timer*2)) #jumpVelocity will be 0 if jump not started on ground
				velocity.y = clamp(velocity.y,-425,510)
		if (Input.is_action_pressed(device+"Jump") and coyote_timer < 0.1) or (Input.is_action_pressed(device+"Jump") and is_on_wall_only()) or (jump_in_progress):
			jump_timer += delta
			jump_in_progress = true
			if not Input.is_action_pressed(device+"Jump"):
				jump_in_progress = false
		change_animation()
				# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_axis(device+"Left", device+"Right")
		if direction:
			#while abs(velocity.x) <= abs(direction*SPEED):
			velocity.x += SPEED*MOVE_ACCEL*direction
			
			if direction > 0: #right
				last_direction = DIRECTION.right
				if velocity.x > direction*SPEED:
					velocity.x = direction*SPEED
				$AnimatedSprite2D.flip_h = false
				$Attack_Hitbox.scale.x = abs($Attack_Hitbox.scale.x)
	
			elif direction < 0: #left
				last_direction = DIRECTION.left
				if velocity.x < direction*SPEED:
					velocity.x = direction*SPEED
				$AnimatedSprite2D.flip_h = true
				$Attack_Hitbox.scale.x = -abs($Attack_Hitbox.scale.x)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED*STOP_ACCEL)
		
		if Input.is_action_just_pressed(device+"Atk"):
			if can_attack:
				attack()
		if Input.is_action_just_pressed(device+"Block"):
			if can_block:
				block()
		move_and_slide()
		
func change_animation():
	if velocity.x != 0:
		move = true
	else:
		move = false
	if !$Attack_Timer.is_stopped():
		atk = true
	else:
		atk = false
	if is_blocking:
		blk = true
	else:
		blk = false
	
	match [move, atk, blk]:
		[false, false, false]:
			$AnimatedSprite2D.animation = "idle"
		[false, false, true]:
			$AnimatedSprite2D.animation = "still_blk"
		[false, true, false]:
			$AnimatedSprite2D.animation = "still_atk"
		[false, true, true]:
			$AnimatedSprite2D.animation = "still_atk_blk"
		[true, false, false]:
			$AnimatedSprite2D.animation = "move"
		[true, false, true]:
			$AnimatedSprite2D.animation = "move_blk"
		[true, true, false]:
			$AnimatedSprite2D.animation = "move_atk"
		[true, true, true]:
			$AnimatedSprite2D.animation = "move_atk_blk"


# DEALING DAMAGE
func attack():
	print(name," attack()")
	$Attack_Hitbox.monitorable = true
	$Attack_Hitbox.monitoring = true
	can_attack = false
	$Attack_Timer.start()

func _on_attack_hitbox_area_entered(area) -> void:
	print(name," _on_attack_hitbox_area_entered()")
	if area != $Damage_Hitbox and area.name == "Damage_Hitbox":
		$Attack_Hitbox.set_deferred("monitoring", false)
		$Attack_Hitbox.set_deferred("monitorable", false)

func _on_attack_timer_timeout() -> void:
	print(name," _on_attack_timer_timeout()")
	if $Attack_Hitbox.monitoring and $Attack_Hitbox.monitorable:
		$Attack_Hitbox.monitorable = false
		$Attack_Hitbox.monitoring = false
	$Attack_Cooldown_Timer.start()
func _on_attack_cooldown_timer_timeout():
	print(name, " _on_attack_cooldown_timer_timeout()")
	can_attack = true


#RECIEVING DAMAGE
func _on_damage_hitbox_area_entered(area):
	print(name," _on_damage_hitbox_area_entered()")
	if area != $Attack_Hitbox and area.name == "Attack_Hitbox":
		damage()

func damage(): 
	print(name," damage()")
	#take damage, play animation, stop attack ability
	if can_block:
		taken_damage = true
		health -= 5
		print("damage done, health left:",health, name)
	else:
		print("attack blocked!")
	
# BLOCKING
func block():
	is_blocking = true
	can_block = false
	$Block_Timer.start()
func _on_block_timer_timeout() -> void:
	is_blocking = false
	$Block_Cooldown_Timer.start()
func _on_block_cooldown_timer_timeout():
	print(name, " _on_block_cooldown_timer_timeout()")
	can_block = true
		
#issues i have had quick access
# speed and gravity values weren't entirely right.
#
# Immediately getting to max speed / min speed
# min speed fixed first with speed*0.16 as delta rather than speed
# max speed fixed by adding acceleration
#
# Move accel did not work correctly in both directions or when switching directions
# split movement into different directions 
# the issue was that i used absolute max speed and velocity values, which caused direction issues due to having
# max speed in one direction when switching caused the code to immediately put me at full acceleration.
#
# stop accel was always the same no matter how fast you were going
# multiplied by speed.
#
# cannot jump on wall. added or is_on_wall()

# wall jump too powerful. separated is_on_wall()
# changed to is_on_wall_only() probably not much difference due to elif but better suited.

# i need to implement coyote time (for a few frames after falling you can still jump)
#
# implemented variable jump height
#
# Jumping on a ceiling gives height. This is not intended.

# Jumping in mid-air gave height. Added is_on_floor() to is_action_just_pressed("Jump_1") and is_action_pressed("Jump_1")

# Variable jumping no longer works as not on floor after jumping. Removing is_on_floor from is_action_pressed("Jump_1"). 
# This works as the change in velocity.y is multiplied by jump_velocity, which is 0.0 unless jumped from floor
# This broke wall jumping as it seems the infinite jump was causing it to work. 
# Fixed by moving is_on_floor to elif after wall jump.

# I think that jump height is too high. Lowering it.

# Refer to line 67
# How Coyote?
# Timer, for frames after fall
# is_on_floor, coyote_timer = 0.0
# not is_on_floor, coyote_timer += delta
# if coyote_timer < 10 or smtn jump
# 0.1 is best value
# this worked !!

# Jumping right before hitting the ground does not jump
# Jump Buffers
# so i already have jump_timer which always goes up when jump pressed
# if jump_timer < 0.5 upon hitting floor, reset jump_timer to 0.01 and jump
# change if_action_just_pressed to add 'or jump_timer < 0.5'

# fixed numbers so jump feels better
# jump buffer was broken but i fixed it by
# jump_timer only starts increasing when on floor
# so add wall to possible start points

# made wall jump  

# coyote jump has less velocity after falling for longer
# start timer on jump rather on leave?
# Limiting jump to if coyote_timer < 0.1 bad, removed
# Same thing but 0.2 was bad for start as if jump started late in coyote, will have less jump
# jump_in_progress variable and now will also jump if jump_in_progress and jump button set.

# issue: timers and jump rely on consistent frame rates.

# issue: jumping adds to velocity, but if gravity, vertical velocity might be down. 
# fix: if velocity.y > 0.0, set to 0.0 before adding

#issue: how flip attack hitbox?:
#fix: different code to flip hitbox: use absolute values

#issue: hitbox only checks once when attack pressed
#fix: disable on hit or timer end, but keep it on until either of those happen

#issue: cannot get colliders on damage hitbox
#fix: change all hitboxes to area2d

#issue: i need to get damage and turn off 
#fix: when attack pressed, enable monitoring and monitorable on atk hitbox, then when either timer stops or when it hits, disable.

#issue: i need to change 2 files when editing code
#fix: change device based on name: implementation was still there from old controller code

#issue: damage code would run twice
#fix: set monitoring and monitorable to false on attack_hitbox after attack hitbox area entered

#issue: not setting monitors to false
#fix: i have to use set_deferred() because i can't turn it off on the same frame

#issue: same issue?
#fix: it actually is doing what i want but i was testing in the same frame.

#issue: health only taken after moving out and in again.
# found self's atk hitbox until attack done once.
# issue probably in the timer cancel function
