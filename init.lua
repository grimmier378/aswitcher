local mq         = require('mq')
local ImGui      = require('ImGui')
local Actors     = require('actors')
local Icons      = require('mq.ICONS')

local MySelf     = mq.TLO.Me
local MyName     = MySelf.CleanName()
local MyClass    = (MySelf.Class.ShortName() or 'unknown'):lower()
local MyActor    = nil

local Boxes      = {}  -- holds actors data
Boxes[MyName]    = nil -- holds my data
local ActorsList = {}  -- holds the list of actors


local isRunning = true
local ShowMain  = false

--- Sort the actors list alphabetically.
local function SortActors()
	ActorsList = {}
	for actorName, actorData in pairs(Boxes) do
		table.insert(ActorsList, actorName)
	end
	table.sort(ActorsList, function(a, b)
		return a < b
	end)
end

-- ACTORS --

local function ActorsHandler()
	MyActor = Actors.register('actorswitcher', function(message)
		local newMessage = message()

		if newMessage.Subject == 'Hello' and newMessage.From ~= MyName then
			if Boxes[newMessage.From] == nil then
				Boxes[newMessage.From] = newMessage.Class
				if MyActor then
					MyActor:send({ mailbox = 'actorswitcher', }, {
						Subject = 'Hello',
						From = MyName,
						Class = MyClass,
					})
				end
				return
			end
		end

		if newMessage.Subject == 'switch' and newMessage.Who:lower() == MyName:lower() then
			mq.cmd("/foreground")
			return
		end
	end)
end

local function CommandHandler(...)
	local args = { ..., }

	if args[1] == 'list' then
		for _, actorName in pairs(ActorsList) do
			if actorName ~= MyName then
				printf("%s (%s)", actorName, Boxes[actorName])
			end
		end
	elseif args[1] == 'hello' then
		printf("Saying Hello")
		if MyActor then
			MyActor:send({ mailbox = 'actorswitcher', }, {
				Subject = 'Hello',
				From = MyName,
				Class = MyClass,
			})
			return
		else
			mq.cmdf("/echo No actor registered for hello.")
		end
	elseif args[1] ~= nil then
		if MyActor then
			MyActor:send({ mailbox = 'actorswitcher', }, {
				Subject = 'switch',
				From = MyName,
				Class = MyClass,
				Who = args[1],
			})
			return
		else
			mq.cmdf("/echo No actor registered for switching.")
		end
	else
		mq.cmdf("/echo Unknown command: %s", args[1])
	end
end

------------------------- Main --------------
local function Init()
	-- initialize Actors
	ActorsHandler()
	mq.bind("/aswitch", CommandHandler)
	if MyActor then
		MyActor:send({ mailbox = 'actorswitcher', }, {
			Subject = 'Hello',
			From = MyName,
			Class = MyClass,
		})
	end
	printf("ActorsSwitcher initialized for %s (%s)", MyName, MyClass)
	printf("Use /aswitch name to switch to another actor.")
	printf("Use /aswitch list to show the list of actors.")
	printf("Use /aswitch hello announce yourself to others (updates list).")
	isRunning = true
end

local function Main()
	while isRunning do
		mq.delay(100)
		SortActors()
	end
	mq.unbind("/aswitch")
end

Init()
Main()
