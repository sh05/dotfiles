return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      filetypes = {
        gitcommit = true,
        yaml = true,
        markdown = true,
      },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = {
      "CopilotChat",
      "CopilotChatExplain",
      "CopilotChatReview",
      "CopilotChatFix",
      "CopilotChatOptimize",
      "CopilotChatDocs",
      "CopilotChatTests",
      "CopilotChatCommit",
    },
    opts = {
      model = "claude-3.7-sonnet",
      prompts = {
        Explain = {
          prompt = "選択したコードの説明を段落として書いてください。",
          system_prompt = "COPILOT_EXPLAIN",
        },
        Review = {
          prompt = "選択したコードをレビューしてください。",
          system_prompt = "COPILOT_REVIEW",
        },
        Fix = {
          prompt = "このコードには問題があります。問題を特定し、修正を加えてコードを書き直してください。何が問題だったのか、そしてあなたの変更がどのように問題を解決するかを説明してください。",
        },
        Optimize = {
          prompt = "選択したコードを最適化して、パフォーマンスと可読性を向上させてください。最適化戦略と変更の利点を説明してください。",
        },
        Docs = {
          prompt = "選択したコードにドキュメントコメントを追加してください。",
        },
        Tests = {
          prompt = "コードのテストを生成してください。",
        },
        Commit = {
          prompt = "コミットメッセージをコミットゼンの規約に従って書いてください。タイトルは50文字以内にし、メッセージは72文字で折り返してください。gitcommitコードブロックとしてフォーマットしてください。",
          context = "git:staged",
        },
      },
    },
  },
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
    },
    cmd = "MCPHub", -- lazy load
    build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
    opts = {
      auto_approve = false,
    },
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    opts = {
      provider = "copilot",
      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model = "claude-3.7-sonnet",
        timeout = 30000,
        temperature = 0,
        max_completion_tokens = 4096,
      },
      -- system_prompt as function ensures LLM always has latest MCP server state
      -- This is evaluated for every message, even in existing chats
      system_prompt = function()
        local hub = require("mcphub").get_hub_instance()
        return hub:get_active_servers_prompt()
      end,
      -- Using function prevents requiring mcphub before it's loaded
      custom_tools = function()
        return {
          require("mcphub.extensions.avante").mcp_tool(),
        }
      end,
      disabled_tools = {
        "list_files", -- Built-in file operations
        "search_files",
        "read_file",
        "create_file",
        "rename_file",
        "delete_file",
        "create_dir",
        "rename_dir",
        "delete_dir",
        "bash", -- Built-in terminal access
      },
    },
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      "ravitemer/mcphub.nvim",
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
    },
  },
}
