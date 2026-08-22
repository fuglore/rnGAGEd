Hooks:PostHook(InteractionTweakData, "init", "reengaged_shorter_lockpicks", function(self)
	self.pick_lock_easy.timer = 4
	self.pick_lock_easy_no_skill.timer = 3
	self.pick_lock_hard.timer = 7
	self.pick_lock_hard_no_skill.timer = 7
	self.pick_lock_deposit_transport.timer = 7
	self.open_door_with_keys.timer = 3
end)