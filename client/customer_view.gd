extends Node2D
## Roaming customers. Identity, destinations and facing come from the host;
## this view smooths snapshots and keeps each customer's art stable.

const Game = preload("res://network/game.gd")
const Customer = preload("res://client/customer.gd")
const CustomerScene = preload("res://client/customer.tscn")

var _customers: Dictionary = {} # customer id -> persistent visual, independent of slot


## Updates the visitors. `remaining` holds the seconds left per customer,
## computed locally so the patience bars drain smoothly between snapshots.
func apply(entries: Array, remaining: Array) -> void:
	var present := {}
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var id := int(entry.get("id", 0))
		present[id] = true
		if not _customers.has(id):
			var spawned := CustomerScene.instantiate()
			spawned.name = "Customer_%d" % id
			add_child(spawned)
			_customers[id] = spawned
		var customer: Customer = _customers[id]
		var total := maxf(float(entry.get("patience_seconds", 1.0)), 0.001)
		customer.show_customer(id, str(entry.get("order", "")), float(remaining[i]) / total, bool(entry.get("angry", false)))
		customer.follow_snapshot(entry)
	for id in _customers.keys():
		if not present.has(id):
			var customer: Customer = _customers[id]
			remove_child(customer)
			customer.queue_free()
			_customers.erase(id)
