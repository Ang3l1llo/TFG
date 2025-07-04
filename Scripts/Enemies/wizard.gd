extends CharacterBody2D

@onready var player = get_node("/root/FinalZone/Player")
@onready var sprite = $AnimatedSprite2D
@onready var detect_zone = $DetectZone
@onready var magic_spawn = $MagicSpawnPoint
@export var fireball_scene: PackedScene
@export var iceball_scene: PackedScene

var can_attack = true
var is_attacking = false
var is_hurt = false
var is_dead = false
var max_health = 500
var current_health = max_health
var speed = 60
var score_points: int = 30

@warning_ignore("UNUSED_SIGNAL")
signal enemy_died

func _physics_process(_delta):
	if current_health <= 0:
		return
	
	if detect_zone.overlaps_body(player) and not is_attacking and not is_hurt:
		velocity = Vector2.ZERO
		move_and_slide()
		await attack_if_possible()
	else:
		movement()

func movement():
	if is_attacking or is_hurt:
		return
	
	var direction = global_position.direction_to(player.global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	if velocity.length() > 0:
		sprite.play("WALK")

		if velocity.x != 0:
			var facing_right = velocity.x > 0
			sprite.scale.x = 1 if facing_right else -1

			# Solo se ajusta si mira a la izquierda
			if not facing_right:
				magic_spawn.position = Vector2(0, 30)  # ajustado a mano cuando rota..
			else:
				magic_spawn.position = Vector2(68, 31)   


func attack_if_possible():
	if not can_attack:
		return

	is_attacking = true
	can_attack = false

	var attack_type = ""
	if randi() % 2 == 0:
		attack_type = "ATTACK1"  # Hielo
	else:
		attack_type = "ATTACK2"  # Fuego

	await play_and_wait(attack_type)
	shoot_projectile(attack_type)

	can_attack = true
	is_attacking = false


func shoot_projectile(attack_type: String):
	var projectile

	if attack_type == "ATTACK1":
		projectile = iceball_scene.instantiate()
	elif attack_type == "ATTACK2":
		projectile = fireball_scene.instantiate()
	else:
		return  

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = magic_spawn.global_position

	var dir = (player.global_position - global_position).normalized()
	projectile.direction = dir

func take_damage(damage_amount: int):
	if current_health <= 0:
		return
	
	current_health -= damage_amount

	is_hurt = true
	velocity = Vector2.ZERO
	move_and_slide()
	
	await play_and_wait("HURT")
	
	is_hurt = false
	
	if current_health <= 0:
		await die()

func die():
	if is_dead:
		return
		
	is_dead = true
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	move_and_slide()
	await play_and_wait("DEATH")
	
	#Drop de cristalito
	var exp_pickup = preload("res://Scenes/Crystals/red_crystal.tscn").instantiate()
	exp_pickup.global_position = sprite.global_position
	get_tree().current_scene.add_child(exp_pickup)
	
	# Sumar puntos al global y actualizar la API
	Global.add_points(score_points)
	
	emit_signal("enemy_died")
	queue_free()

func play_and_wait(animation_name: String):
	sprite.play(animation_name)
	await sprite.animation_finished
