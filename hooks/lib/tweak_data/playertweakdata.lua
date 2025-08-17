Hooks:PostHook(PlayerTweakData, "init", "reengage_height_stuff", function(self)
	self.movement_state.standard.movement.jump_velocity.z = 500
	
	self.stances.default.crouched_peeking = deep_clone(self.stances.default.crouched)
	self.stances.default.crouched_peeking.head.translation = Vector3(0, 0, 110)
end)