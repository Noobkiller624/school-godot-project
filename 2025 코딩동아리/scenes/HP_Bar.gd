extends ProgressBar

func _ready() -> void:
	# ProgressBar의 최대값 설정 (예: 최대 체력)
	max_value = 100   # Global.MAX_HP를 미리 정의했다고 가정
	value = Global.HP           # 처음 값 설정, 변수 접근

func _process(delta: float) -> void:
	# 매 프레임마다 ProgressBar 값 갱신
	value = Global.HP           # 변수 접근으로 최신 HP 반영
