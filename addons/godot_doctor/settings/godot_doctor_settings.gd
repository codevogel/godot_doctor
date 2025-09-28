extends Resource
class_name GodotDoctorSettings

@export var show_debug_prints: bool = false
@export var show_toasts: bool = true
@export var default_dock_position: DockSlot = DockSlot.DOCK_SLOT_LEFT_BR

enum DockSlot {
	DOCK_SLOT_LEFT_UL = 0,
	DOCK_SLOT_LEFT_BL = 1,
	DOCK_SLOT_LEFT_UR = 2,
	DOCK_SLOT_LEFT_BR = 3,
	DOCK_SLOT_RIGHT_UL = 4,
	DOCK_SLOT_RIGHT_BL = 5,
	DOCK_SLOT_RIGHT_UR = 6,
	DOCK_SLOT_RIGHT_BR = 7,
}
