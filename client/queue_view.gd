extends Node2D
## The queue in front of the serving counter: one customer drawing per waiting
## customer the authority published, each on a shared queue slot. This node
## only draws - main.gd hands it the snapshot's customers and how long each of
## them has left.

const Game = preload("res://network/game.gd")
const Customer = preload("res://client/customer.gd")
const CustomerScene = preload("res://client/customer.tscn")

var _customers: Array = []


## Rebuilds the queue. `remaining` holds the seconds left per customer,
## computed locally so the patience bars drain smoothly between snapshots.
func apply(entries: Array, remaining: Array) -> void:
	while _customers.size() < entries.size():
		var spawned := CustomerScene.instantiate()
		add_child(spawned)
		_customers.append(spawned)
	for i in _customers.size():
		var customer: Customer = _customers[i]
		if i >= entries.size():
			customer.visible = false
			continue
		customer.visible = true
		customer.position = Game.QUEUE_SLOTS[mini(i, Game.QUEUE_SLOTS.size() - 1)]
		var entry: Dictionary = entries[i]
		var total := maxf(float(entry.get("patience_seconds", 1.0)), 0.001)
		customer.show_customer(int(entry.get("id", 0)), str(entry.get("order", "")), float(remaining[i]) / total, bool(entry.get("angry", false)))
