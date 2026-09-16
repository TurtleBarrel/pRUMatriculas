extends VSplitContainer

@onready var entries_pinned:VBoxContainer = %Entries_pinned
@onready var entries_unpinned: VBoxContainer = %Entries_unpinned

@onready var column_titles_panel: PanelContainer = %column_titles_panel

var shown:bool = false
var offset_pre_hide:float = 0
var dragging:bool = false

var first_load_split:bool = true
var first_load_pinned:bool = true
func _ready() -> void:
	self.resized.connect(
		func():
			if first_load_split == true:
				update_vis()
				first_load_split = false
	)
	
	owner.pins_changed.connect(
		func(added:bool):
			if dragging == false and first_load_pinned == false:
				update_size(added)
				update_vis()
			first_load_pinned = false
	)

func update_size(added:bool):
	if added == true:
		
		var offsets = self.split_offsets
		if offsets[0] < -self.size.y/2 + entries_pinned.size.y + 80:
			offsets[0] = -self.size.y/2 + entries_pinned.size.y + 80
			self.split_offsets = offsets

func update_vis() -> void:
	if entries_pinned.get_child_count() == 0:
		offset_pre_hide = split_offsets[0]
		var offsets = self.split_offsets
		offsets[0] = -self.size.y
		self.split_offsets = offsets
		self.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
		shown = false
		column_titles_panel.visible = false
	
	elif shown == false:
		var offsets = self.split_offsets
		offsets[0] = offset_pre_hide
		self.split_offsets = offsets
		self.dragger_visibility = SplitContainer.DRAGGER_VISIBLE
		shown = true
		column_titles_panel.visible = true

func _on_drag_started() -> void:
	dragging = true
func _on_drag_ended() -> void:
	dragging = false
