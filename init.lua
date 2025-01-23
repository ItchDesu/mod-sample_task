
local task_id = "step_50_nodes"
local task_def = {
	title = "Walk 50 Nodes",
	description = "Just walk around.",
	meta = {
		req_steps = 50
	},

	is_complete = function(self, player)
		-- task is "complete" if player walked the number of nodes designated in `TaskDef.meta.req_steps`
		return (tonumber(tasks.get_player_state(player, self.id, 1)) or 0) >= self.meta.req_steps
	end,

	on_complete = function(self, player)
		-- send message & play sound to notify player task complete
		core.chat_send_player(player:get_player_name(), "Completed task: \"" .. self.title .. "\"")
		core.sound_play({name="sample_task_fanfare"}, {to_player=player:get_player_name()})
	end,

	get_log = function(self, player)
		local desc = {}

		if self:is_complete(player) then
			table.insert(desc, "I have completed the task.")
		else
			table.insert(desc, "I have not yet walked far enough.")
		end
		-- index 1 represents number of steps player has taken since task began
		local steps = tonumber(tasks.get_player_state(player, self.id, 1)) or 0
		table.insert(desc, "I have taken " .. steps .. " out of " .. self.meta.req_steps .. " steps.")

		return desc
	end,

	logic = function(self, dtime, player)
		local pos = player:getpos()
		if pos == nil then
			core.log("warning", "Could not determine position of player " .. player:get_player_name())
			return
		end
		-- Note: movement on Z axis doesn't count
		pos = {x=math.floor(pos.x), y=math.floor(pos.y)}
		-- index 2 represents player's position at previous call
		local old_pos = core.deserialize(tasks.get_player_state(player, self.id, 2)) or pos
		local steps_taken = math.abs(pos.x - old_pos.x) + math.abs(pos.y - old_pos.y)
		-- FIXME: compensate for teleporting
		if steps_taken > 0 then
			-- index 1 represents number of steps player has taken since task began
			local total_steps = (tonumber(tasks.get_player_state(player, self.id, 1)) or 0) + steps_taken
			if total_steps > self.meta.req_steps then
				total_steps = self.meta.req_steps
			end
			-- set new position first as setting steps count may trigger `TaskDef:on_complete`
			tasks.set_player_state(player, self.id, 2, core.serialize(pos))
			tasks.set_player_state(player, self.id, 1, total_steps)
		end
	end
}

tasks.register(task_id, task_def)

core.register_on_joinplayer(function(player, last_login)
	local pos = player:getpos()
	pos = {x=math.floor(pos.x), y=math.floor(pos.y)}
	-- task initialization triggered by login (reset every login)
	tasks.set_player_state(player, task_id, "0;" .. core.serialize(pos))
end)

core.register_on_leaveplayer(function(player, timed_out)
	-- clean up player meta since we don't want sample task data to persist
	tasks.set_player_state(player, task_id)
	if tasks.player_has(player, task_id) then
		core.log("warning", "Failed to clean up sample task with ID \"" .. task_id .. "\" for player "
				.. player:get_player_name())
	end
end)

-- chat command to check task state for current player
core.register_chatcommand("sample_task", {
	params = "",
	description = "Print state string of sample task for current player.",
	privs = {},
	func = function(name, param)
		local player = core.get_player_by_name(name)
		local state = tasks.get_player_state(player, task_id)
		core.chat_send_player(name, "Sample task state: " .. state)
	end
})
