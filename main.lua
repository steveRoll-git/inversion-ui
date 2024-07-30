local roomy = require "lib.roomy"

local manager = roomy.new()

---@type MenuData
local menuData = {
  title = "Main Menu",
  items = {
    {
      title = "Continue",
      items = {
        {
          title = "Level 1"
        },
        {
          title = "Level 2"
        },
        {
          title = "Level 3"
        },
        {
          title = "Level 4"
        },
        {
          title = "Level 5"
        },
      }
    },
    {
      title = "New Game",
      items = {
        {
          title = "Easy"
        },
        {
          title = "Normal"
        },
        {
          title = "Hard"
        },
      }
    },
    {
      title = "Options",
      items = {
        {
          title = "Graphics",
          items = {
            {
              title = "Fullscreen"
            },
            {
              title = "Resolution"
            },
          }
        },
        {
          title = "Sound"
        },
        {
          title = "Controls"
        },
      }
    },
    {
      title = "Exit",
      items = {
        {
          title = "Yes"
        },
        {
          title = "No"
        },
      }
    },
  }
}

function love.load()
  manager:hook()
  manager:enter(require "menu", menuData)
end
