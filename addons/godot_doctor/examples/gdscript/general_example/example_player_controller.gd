## A simple example player controller demonstrating default export validation.
## Used by GodotDoctor to show how default validations catch unassigned exported nodes.
class_name ExamplePlayerController
extends Node

## The player node this controller acts upon. Must be assigned before play.
@export var player: Node
