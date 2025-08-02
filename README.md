# State-luau
Super simple state manager (will do proper type checking in the future currently there is no way to make it type safe)
# Example
```luau
local state = require("../state")

local foo = state.create({
  health = 50,
  items = {
    apple = 1
  }
})

state.middleware(foo, function(data)
  if data.health > 100 then
    data.health = 100
	print("health cannot exceed 100")
  end
  return data
end)

local unsubscribe = state.subscribe(foo, function(data)
  return data.health
end, function(current_health, previous_health)
  print(`current health: {current_health}, previous health: {previous_health}`)
end)

state.set(foo, {
  health = 125,
  items = {
    apple = 2,
  }
})

local items = state.get(foo, "items")
print(`apples: {items.apple}`)

unsubscribe()
```
