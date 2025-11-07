class_name NodeUtils

## Utility functions for safe node operations.
## Provides consistent null/validity checking patterns.

## Check if a node is both non-null and still valid in the scene tree.
## Uses Variant type to accept freed nodes without type checking errors.
static func is_valid(node: Variant) -> bool:
	if node == null:
		return false
	if not is_instance_valid(node):
		return false
	return true

## Safely queue_free a node if it's valid.
static func safe_queue_free(node: Variant) -> void:
	if is_valid(node):
		node.queue_free()

## Safely call a method on a node if it exists and is valid.
static func safe_call(node: Variant, method: String, args: Array = []) -> Variant:
	if is_valid(node) and node.has_method(method):
		return node.callv(method, args)
	return null

## Get first node in group, returns null if not found or invalid.
static func get_first_in_group(tree: SceneTree, group_name: String) -> Node:
	var node: Node = tree.get_first_node_in_group(group_name)
	return node if is_valid(node) else null

## Get all valid nodes in a group.
static func get_valid_nodes_in_group(tree: SceneTree, group_name: String) -> Array[Node]:
	var nodes: Array[Node] = []
	for node in tree.get_nodes_in_group(group_name):
		if is_valid(node):
			nodes.append(node)
	return nodes
