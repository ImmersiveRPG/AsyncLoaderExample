# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/GodotAsyncLoader

extends Node

var _is_running := false
var _thread : Thread
var _to_instance := []
var _to_instance_mutex := Mutex.new()


func instance_with_cb(packed_scene : PackedScene, instanced_cb : FuncRef, data : Dictionary, has_priority : bool, is_sleeping_children : bool) -> void:
	var entry := {
		"packed_scene" : packed_scene,
		"instanced_cb" : instanced_cb,
		"data" : data,
		"has_priority" : has_priority,
		"is_sleeping_children" : is_sleeping_children,
	}

	_to_instance_mutex.lock()
	if has_priority:
		_to_instance.push_front(entry)
	else:
		_to_instance.push_back(entry)
	_to_instance_mutex.unlock()

func _run_instancer_thread(_arg : int) -> void:
	_is_running = true
	var config = get_node("/root/AsyncLoaderConfig")

	while _is_running:
		_to_instance_mutex.lock()
		var to_instance := _to_instance.duplicate()
		_to_instance.clear()
		_to_instance_mutex.unlock()

		for entry in to_instance:
			var packed_scene = entry["packed_scene"]
			var instanced_cb = entry["instanced_cb"]
			var data = entry["data"]

			# Instance the scene
			var instance = packed_scene.instance()

			# Send the instance to the callback in the main thread
			instanced_cb.call_deferred("call_func", instance, data)
			#print("  SceneInstancer.thread: %s, instanced_cb: %s, instance: %s" % [data["scene_path"].split('/')[-1], instanced_cb.function, instance])

		OS.delay_msec(config._thread_sleep_msec)


