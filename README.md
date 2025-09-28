# Godot Doctor 🩺

A powerful scene validation plugin for Godot that provides a cleaner, more maintainable alternative to `_get_configuration_warnings()`, that doesn't require gameplay scripts to be `@tool`.

## What is Godot Doctor?

Godot Doctor is a Godot plugin that validates your scenes and nodes using a declarative, test-driven approach. Instead of writing procedural warning code, you define validation conditions using callables that focus on validation logic first, with error messages as metadata.

## Why Use Godot Doctor?

### 🏷️ **No `@tool` Required**
Unlike `_get_configuration_warnings()`, Godot Doctor works without requiring the `@tool` annotation on your scripts.
This means that you no longer have to muddy up your gameplay code with editor-specific logic, such as:

| Traditional `_get_configuration_warnings()` | Godot Doctor Approach |
|---|---|
| ```gdscript<br>@tool<br>extends Node<br>class_name MyNode<br><br>@export var my_button: Button<br><br>func _ready():<br>   my_button.pressed.connect(_on_button_pressed)<br><br>func _get_configuration_warnings():<br>   var errors: PackedStringArray = []<br>   if not my_button:<br>      errors.append("my_button is not assigned!")<br>   return errors<br><br>func _on_button_pressed():<br>   # do something<br><br>func _notification(what: int) -> void:<br>   match what:<br>      NOTIFICATION_EDITOR_POST_SAVE:<br>            update_configuration_warnings()<br>``` | ```gdscript<br>extends Node<br>class_name MyNode<br><br>@export var my_button: Button<br><br>func _ready():<br>   my_button.pressed.connect(_on_button_pressed)<br><br>func _get_validation_conditions() -> Array[ValidationCondition]:<br>   return [<br>      ValidationCondition.simple(<br>         my_button != null,<br>         "my_button is not assigned!"<br>      )<br>   ]<br><br>func _on_button_pressed():<br>   # do something<br>``` |



### 🧪 **Test-Driven Validation**
Write validation logic that resembles unit tests rather than procedural warning generators. This encourages:
- More organized code
- Better maintainability 
- Human-readable validation conditions
- Separation of concerns between logic and messaging

### 🔄 **Automatic Scene Validation**
Validations run automatically when you save scenes, providing immediate feedback during development.

### 🎯 **Declarative Syntax**
Define what should be true rather than writing code to generate warnings.

## Validation Syntax

### Basic ValidationCondition

The core of Godot Doctor is the `ValidationCondition` class, which takes a callable and an error message:

```gdscript
# Basic validation condition
var condition = ValidationCondition.new(
    func(): return health > 0,
    "Health must be greater than 0"
)
```

### Simple Static Method

For basic boolean checks, use the convenience `simple()` method:

```gdscript
# Equivalent to the above, but more concise
var condition = ValidationCondition.simple(
    health > 0,
    "Health must be greater than 0"
)
```

### Implementing Validation in Your Nodes

Add a `_get_validation_conditions()` method to any node you want to validate:

```gdscript
extends CharacterBody2D

@export var max_health: int = 100
@export var speed: float = 200.0
@export var weapon: PackedScene

func _get_validation_conditions() -> Array[ValidationCondition]:
    return [
        ValidationCondition.simple(
            max_health > 0,
            "Max health must be greater than 0"
        ),
        ValidationCondition.simple(
            speed > 0,
            "Speed must be positive"
        ),
        ValidationCondition.simple(
            weapon != null,
            "Weapon scene must be assigned"
        )
    ]
```

### Advanced Validation with Callables

For more complex validation logic, use callables:

```gdscript
func _get_validation_conditions() -> Array[ValidationCondition]:
    return [
        ValidationCondition.new(
            func(): return _validate_component_setup(),
            "Component setup is invalid"
        ),
        ValidationCondition.new(
            func(): return _check_dependencies(),
            "Missing required dependencies"
        )
    ]

func _validate_component_setup() -> bool:
    # Complex validation logic here
    return has_node("CollisionShape2D") and has_node("Sprite2D")

func _check_dependencies() -> bool:
    # Check for required autoloads, resources, etc.
    return GameManager != null and PlayerData != null
```

### Nested Validation Conditions

Validation conditions can return arrays of other validation conditions for hierarchical validation:

```gdscript
func _get_validation_conditions() -> Array[ValidationCondition]:
    return [
        ValidationCondition.new(
            func(): return _get_inventory_validations(),
            "Inventory validation failed"
        )
    ]

func _get_inventory_validations() -> Array[ValidationCondition]:
    var conditions: Array[ValidationCondition] = []
    
    for item in inventory_items:
        conditions.append(ValidationCondition.simple(
            item.quantity > 0,
            "Item '%s' has invalid quantity" % item.name
        ))
    
    return conditions
```

## How It Works

1. **Automatic Discovery**: When you save a scene, Godot Doctor scans all nodes for the `_get_validation_conditions()` method
2. **Instance Creation**: For non-`@tool` scripts, temporary instances are created to run validation logic
3. **Condition Evaluation**: Each validation condition's callable is executed
4. **Error Reporting**: Failed conditions display their error messages in the Godot Doctor dock
5. **Navigation**: Click on errors in the dock to navigate directly to the problematic nodes

## Examples

For detailed examples and common validation patterns, see [./addons/godot_doctor/examples/README.md](./addons/godot_doctor/examples/README.md).

## Installation

1. Copy the `addons/godot_doctor` folder to your project's `addons/` directory
2. Enable the plugin in Project Settings > Plugins
3. The Godot Doctor dock will appear in the editor's left panel

## License

Godot Doctor is released under the MIT License. See the LICENSE file for details.
