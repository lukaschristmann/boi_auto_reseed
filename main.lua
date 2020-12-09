local	autoreseed = RegisterMod( "Auto Reseed" ,1 );

-- Determines whether to search for a run with
-- Curse of the Labyrinth.
-- Default: false
local searchLabyrinth = false;

-- Determines the maximum amount of reseeds when
-- in XXXXL challenge to limit time and apparent hangs.
-- Default: 3000
local numReseedsXXL = 3000;

-- Enables a few things to ease development, like restarting the game
-- When the mod is reloaded
-- Default: false
local debug = false;

local function console(stuff)
  if debug then
    Isaac.ConsoleOutput(tostring(stuff))
    Isaac.DebugString("AutoReseed:" .. tostring(stuff))
  end
end

local slots = {DoorSlot.LEFT0, DoorSlot.LEFT1, DoorSlot.UP0, DoorSlot.UP1, DoorSlot.RIGHT0, DoorSlot.RIGHT1, DoorSlot.DOWN0, DoorSlot.DOWN1}

---[[
local function canHaveCurseLabyrinth()
  local level = Game():GetLevel()
  local stage = level:GetStage()
  
  return level:CanStageHaveCurseOfLabyrinth(stage)
end
--]]

---[[
local function hasCurseLabyrinth()
  
  local level = Game():GetLevel()
  local curses = level:GetCurses();
  
  -- Look Through Curse flags to find Curse of the Labyrinth
  local i = 1;
  while curses > 0 do
    local rem = curses % 2;
    if i == LevelCurse.CURSE_OF_LABYRINTH then
      if rem == 1 then
        return true;
      else
        return false;
      end
    end
    
    curses = curses >> 1;
    i = i+1;
  end
  return false;
end
--]]

---[[
local function restart()
	Isaac.ExecuteCommand("reseed")
  
  -- Seems cleaner, Crashes.
	-- Game():GetSeeds():SetStartSeed("")
	
  -- Also seems cleaner, also crashes
	-- currentChallenge = Isaac.GetChallenge()
	-- Game():GetSeeds():Restart(currentChallenge)
end
--]]

---[[
-- Returns whether a treasure room was spawned directly adjacent to the current room.
local function hasAdjacentTreasureRoom()
  -- Get the current room
	startRoom = Game():GetRoom()
	local treasureRoomFound = false
  
  --Iterate all door slots
	for i, doorSlot in ipairs(slots) do
		door = startRoom:GetDoor(doorSlot)
    
    -- If there is a door
		if door then 
      --Check whether its a treasure room
			isTreasureRoom = door:IsRoomType(RoomType.ROOM_TREASURE)
			treasureRoomFound = treasureRoomFound or isTreasureRoom
		end
  end
	
  -- Return whether the room was found
	return treasureRoomFound
end
--]]

---[[
local function hasTreasureRoom()
  --console("Searching treasure room");
  --Get room Descriptors to search for the treasure rooms
  local level = Game():GetLevel();
  --console("Got level");
  local rooms = level:GetRooms();
  --console("Got rooms");
  local roomnum = level:GetRoomCount();
  --console("Got room count");
  
  --Filter treasure rooms out
  local j=0;
  local treasures={};
  for i=0, roomnum-1 do
    local roomDescriptor = rooms:Get(i);
    room = roomDescriptor.Data;
    if room.Type == RoomType.ROOM_TREASURE then
      return true;
    end
  end
  return false;
end
--]]

---[[
-- Callback to be run on Game start.
-- Receives a boolean whether it was run from a savegame
function autoreseed:onStart(fromSave)
  -- Remember how many times we had to reroll
  local reseeds = 0
	Isaac.ConsoleOutput("New game started.")
  
  console(hasTreasureRoom());
  console("Outputted hasTreasureRoom()");
  local reseed = true;
  repeat
    -- no need to reroll if the game was started from a save
    reseed = not fromSave;
    --console(fromSave);
    --console("after fromSave: " .. tostring(reseed));
    
    -- if not already need to reroll check whether there's item rooms (in case of challenge)
    if reseed then
      local isNoChallenge = Isaac.GetChallenge() == Challenge.CHALLENGE_NULL
      --console(isNoChallenge);
      local canHaveAdjacentItemRoom = isNoChallenge or hasTreasureRoom();
      --console(canHaveAdjacentItemRoom);
      --console(hasAdjacentTreasureRoom());
      reseed = canHaveAdjacentItemRoom and (not hasAdjacentTreasureRoom())
    end
    console("after adjacent treasure: " .. tostring(reseed));
    
    -- if not already need to reroll, check whether we want (and have) a labyrinth
    if not reseed then
      local isNoChallenge = Isaac.GetChallenge() == Challenge.CHALLENGE_NULL
      reseed = isNoChallenge and searchLabyrinth and canHaveCurseLabyrinth() and (not hasCurseLabyrinth());
      console(canHaveCurseLabyrinth());
      console(hasCurseLabyrinth());
    end
    console("after labyrinth: " .. tostring(reseed));
      
    if reseed then
      restart();
      reseeds = reseeds + 1;
    end
    
    reseeds = reseeds + 1;
  until (not reseed) or (Isaac.GetChallenge() == Challenge.CHALLENGE_XXXXXXXXL and (reseeds > numReseedsXXL)) --or (debug and (reseeds > 150))
  
	Isaac.ConsoleOutput("Finished MC_POST_GAME_STARTED callback with ".. reseeds .." reseeds.")
end

autoreseed:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, autoreseed.onStart)
--]]

---[[
-- Debug code to ease development
-- Restarts game when mod is reloaded
if debug then
  Isaac.ExecuteCommand("restart");
end
--]]
