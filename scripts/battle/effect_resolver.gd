class_name EffectResolver
extends RefCounted

## Central place for resolving card effects. Future effects go here or into
## dedicated effect classes without changing CardData.
static func resolve(effect: EffectData, context: EffectContext) -> void:
	match effect.type:
		EffectData.Type.DAMAGE:
			context.enemy_hp = maxi(0, context.enemy_hp - effect.amount)
		EffectData.Type.BLOCK:
			context.player_block += effect.amount
		EffectData.Type.DRAW:
			context.draw_requested += effect.amount
		EffectData.Type.GAIN_DOOM:
			context.doom += effect.amount
		EffectData.Type.GAIN_MULTIPLIER:
			context.multiplier += effect.amount
		EffectData.Type.SELF_DAMAGE:
			context.player_hp = maxi(0, context.player_hp - effect.amount)
