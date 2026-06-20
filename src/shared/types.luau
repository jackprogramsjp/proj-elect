export type function Writable(ty: type): type
	local result = types.copy(ty)
	for key, value in result:properties() do
		result:setproperty(key, value.read)
	end
	return result
end

export type Account = {
	read gold: number,
}

export type GameState = {
	read message: string,
}

local accountTemplate: Account = {
	gold = 0,
}

local gameTemplate: GameState = {
	message = "Hello",
}

return {
	accountTemplate = accountTemplate,
	gameTemplate = gameTemplate,
}
