-- Public-facing loader. Contains no game logic — safe to distribute freely.
-- Buyers set getgenv().key before running this, or enter it in the prompt.
local KEY_SERVER_URL = "https://keys.w8rldisyours.com"

assert(type(loadstring) == "function", "[W8rldisyours219] loadstring is not available in this executor")

local function computeHwid()
	local ok, id = pcall(function()
		if gethwid then
			return tostring(gethwid())
		end
		return tostring(game:GetService("RbxAnalyticsService"):GetClientId())
	end)
	return (ok and id and tostring(id) ~= "") and id or "unknown-hwid"
end

local function encodeQueryValue(value)
	return tostring(value or ""):gsub("([^%w%-_%.~])", function(char)
		return string.format("%%%02X", string.byte(char))
	end)
end

-- Reuses the same Discord UI Lib as the main script so the key prompt
-- matches its look. Falls back to a plain assert if the lib can't load.
local function promptForKey()
	local ok, source = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/GhostDuckyy/UI-Libraries/main/Discord%20Ui%20Lib/source.lua")
	end)
	if not ok or type(source) ~= "string" or #source < 200 then
		return nil
	end

	local chunk = loadstring(source)
	if not chunk then
		return nil
	end

	local libOk, lib = pcall(chunk)
	if not libOk or not lib then
		return nil
	end

	local window = lib:Window("W8rldisyours219")
	local server = window:Server("License", "")
	local channel = server:Channel("enter-key")

	local submittedKey
	channel:Textbox("License Key", "XXXXX-XXXXX-XXXXX-XXXXX", false, function(text)
		text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if text ~= "" then
			submittedKey = text
		end
	end)

	local wait = (task and task.wait) or wait
	while not submittedKey do
		wait(0.1)
	end

	pcall(function()
		local root = game:GetService("CoreGui"):FindFirstChild("Discord")
		if root then
			root:Destroy()
		end
	end)

	return submittedKey
end

local function fetchGatedSource()
	local env = (getgenv and getgenv()) or _G
	local key = tostring(env["key"] or env["W8rldisyours219Key"] or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if key == "" then
		key = promptForKey()
		assert(key, "[W8rldisyours219] Set getgenv().key = \"YOUR-KEY\" before running this loader.")
		env["key"] = key
	end

	local hwid = computeHwid()
	local okEncode, payload = pcall(function()
		return game:GetService("HttpService"):JSONEncode({ key = key, hwid = hwid })
	end)
	assert(okEncode, "[W8rldisyours219] Failed to build the license request")

	local responseBody, lastError = nil, "no reachable key server"
	local requestFn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
	if requestFn then
		local ok, result = pcall(function()
			return requestFn({
				Url = KEY_SERVER_URL .. "/script/fetch",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = payload,
			})
		end)
		if ok and type(result) == "table" then
			local statusCode = tonumber(result.StatusCode or result.Status or result.statusCode) or 0
			if statusCode >= 200 and statusCode < 300 then
				responseBody = result.Body or result.body
			else
				local decodeOk, decoded = pcall(function()
					return game:GetService("HttpService"):JSONDecode(result.Body or result.body or "")
				end)
				lastError = (decodeOk and decoded and decoded.error) or ("HTTP " .. tostring(statusCode))
			end
		end
	end

	if not responseBody then
		-- GET-bridge fallback for executors whose request() is blocked.
		local url = KEY_SERVER_URL .. "/script/fetch?payload=" .. encodeQueryValue(payload)
		local ok, text = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(text) == "string" and text ~= "" then
			-- A JSON error object means the key check failed; real source
			-- never starts with "{" in this codebase.
			local looksLikeError = text:sub(1, 1) == "{"
			if looksLikeError then
				local decodeOk, decoded = pcall(function()
					return game:GetService("HttpService"):JSONDecode(text)
				end)
				lastError = (decodeOk and decoded and decoded.error) or "invalid response"
			else
				responseBody = text
			end
		end
	end

	assert(responseBody, "[W8rldisyours219] License check failed: " .. tostring(lastError))
	return responseBody
end

local ok, source = pcall(fetchGatedSource)
assert(ok, tostring(source))
assert(type(source) == "string" and source ~= "", "[W8rldisyours219] Empty script source received")

local chunk, compileError = loadstring(source)
assert(chunk, "[W8rldisyours219] compile failed: " .. tostring(compileError))

return chunk()
