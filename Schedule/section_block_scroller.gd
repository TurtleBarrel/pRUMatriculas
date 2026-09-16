extends ScrollContainer

@onready var scroll_bar:VScrollBar = self.get_v_scroll_bar()
var remote_scroll:bool = false

func _ready() -> void:
	gs.section_block_scrolled.connect(set_scroll)
	scroll_bar.value_changed.connect(send_scroll_percent)

func send_scroll_percent(_value):
	if remote_scroll == false:
		gs.section_block_scrolled.emit(scroll_bar.ratio, self)
	else:
		remote_scroll = false
		
func set_scroll(percent, source):
	if source != self:
		remote_scroll = true ## Prevents sending the signal when the value is changed to match another
		scroll_bar.ratio = percent
