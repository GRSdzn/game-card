class_name EffectData
extends Resource

## Small composable effect description. Keep logic in EffectResolver, data here.
enum Type {
	DAMAGE,
	BLOCK,
	DRAW,
	GAIN_DOOM,
	GAIN_MULTIPLIER,
	SELF_DAMAGE,
}

@export var type: Type = Type.DAMAGE
@export var amount: int = 0

func describe() -> String:
	match type:
		Type.DAMAGE: return LocalizationManager.translate(&"EFFECT_DAMAGE", {"amount": amount})
		Type.BLOCK: return LocalizationManager.translate(&"EFFECT_BLOCK", {"amount": amount})
		Type.DRAW: return LocalizationManager.translate(&"EFFECT_DRAW", {"amount": amount})
		Type.GAIN_DOOM: return LocalizationManager.translate(&"EFFECT_GAIN_DOOM", {"amount": amount})
		Type.GAIN_MULTIPLIER: return LocalizationManager.translate(&"EFFECT_GAIN_MULTIPLIER", {"amount": amount})
		Type.SELF_DAMAGE: return LocalizationManager.translate(&"EFFECT_SELF_DAMAGE", {"amount": amount})
	return LocalizationManager.translate(&"CARD_NO_EFFECT")
