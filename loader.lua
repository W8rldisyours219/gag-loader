-- Public-facing loader. Contains no game logic — safe to distribute freely.
-- Buyers set getgenv().key before running this.
--
-- EDIT THIS before distributing: your tunneled key-server URL (the SAME
-- value as KEY_SERVER_URL in W8rldisyours219.lua's checkLicenseKey()).
local KEY_SERVER_URL = "https://keys.w8rldisyours.com"

-- Only used while KEY_SERVER_URL is blank (local development before you've
-- deployed the key server) — points at your own repo. Make that repo
-- PRIVATE once you release publicly; this fallback then only works for you.
local DEV_SOURCE_URL = "https://raw.githubusercontent.com/W8rldisyours219/gag-stock-weather-executor/main/W8rldisyours219.lua"

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

local function fetchGatedSource()
	local env = (getgenv and getgenv()) or _G
	local key = tostring(env["key"] or env["W8rldisyours219Key"] or ""):gsub("^%s+", ""):gsub("%s+$", "")
	assert(key ~= "", "[W8rldisyours219] Set getgenv().key = \"YOUR-KEY\" before running this loader.")

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

local ok, source
if KEY_SERVER_URL ~= "" then
	ok, source = pcall(fetchGatedSource)
	assert(ok, tostring(source))
else
	ok, source = pcall(function()
		return game:HttpGet(DEV_SOURCE_URL)
	end)
	assert(ok, "[W8rldisyours219] HttpGet failed: " .. tostring(source))
end

assert(type(source) == "string" and source ~= "", "[W8rldisyours219] Empty script source received")

local chunk, compileError = loadstring(source)
assert(chunk, "[W8rldisyours219] compile failed: " .. tostring(compileError))

return chunk()
