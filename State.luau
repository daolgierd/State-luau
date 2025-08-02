--!nocheck

local function deep_copy(original, seen)
  -- typical luau type solver problems forcing me to do shadow declaration
  local seen = seen or {}

  if type(original) ~= "table" then
    return original
  end

  if seen[original] then
    return seen[original]
  end

  local copy = table.create(#original)
  seen[original] = copy

  for key, value in original do
    key = type(key) == "table" and deep_copy(key, seen) or key
    copy[key] = deep_copy(value, seen)
  end

  return copy
end

local function deep_equal(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end

  for i, v in a do
    if not deep_equal(v, b[i]) then
      return false
    end
  end

  for i, v in b do
    if a[i] == nil then
      return false
    end
  end

  return true
end

local function create(initial)
  return {
    data = deep_copy(initial),
    listeners = {},
    middleware = {}
  }
end

local function get(state, key)
  if key then
    return deep_copy(state.data[key])
  end
  return deep_copy(state.data)
end

local function set(state, new_state)
  local previous = deep_copy(state.data)

  if type(new_state) == "function" then
    local computed = new_state(previous)
    state.data = computed
  else
    for i, v in new_state do
      state.data[i] = v
    end
  end

  for _, middleware in state.middleware do
    if not middleware then continue end
    state.data = middleware(state.data)
  end

  if not deep_equal(previous, state.data) then
    for _, listener in state.listeners do
      if not listener then continue end
      listener(state.data, previous)
    end
  end

  return state.data
end

local function subscribe(state, selector, callback)
  local previous_value = selector(state.data)

  local function listener(current_data, previous_data)
    local current_value = selector(current_data)
    if current_value ~= previous_value then
      callback(current_value, previous_value)
      previous_value = current_value
    end
  end

  table.insert(state.listeners, listener)

  return function()
    for i, listener in ipairs(state.listeners) do
      if listener == listener then
        table.remove(state.listeners, i)
        break
      end
    end
  end
end

local function middleware(state, middleware)
  table.insert(state.middleware, middleware)
end

return table.freeze {
  create = create,
  get = get,
  set = set,
  subscribe = subscribe,
  middleware = middleware,
}
