return {
  {
    "mason-org/mason.nvim",
    opts = {}
  },
  {
    "nvim-java/nvim-java",
    -- Load only when actually opening a Java file: its startup-time JDK/jdtls
    -- download + check blocks every nvim launch (and any nvim --embed child).
    ft = "java",
    dependencies = {
      "nvim-java/lua-async-await",
    },
    config = function()
      require("java").setup({
        jdk = {
          auto_install = true,
        },
        jdtls = {
          version = "1.54.0"
        },
        spring_boot_tools = { enable = true },
        java_test = { enable = false }
      })
      vim.lsp.enable('jdtls')
    end
  },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'onsails/lspkind-nvim',
      "neovim/nvim-lspconfig",
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc, silent = true })
          end

          map('K', function() vim.lsp.buf.hover({ border = 'rounded' }) end, '[K] Hover')
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('g.', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('gr', vim.lsp.buf.references, '[G]oto [R]eferences')
          map('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
          map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          map('<leader>xx', ":lua vim.diagnostic.setqflist()<CR>", 'Open diagnostics')

          map('<leader>ru', function()
            vim.lsp.buf.code_action({ 
              context = {
                only = {
                  "source.organizeImports" 
                }
              }, 
              apply = true 
            })
          end, "Clear unused imports")

          -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer some lsp support methods only in specific files
          ---@return boolean
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_completion, event.buf) then
            -- autotrigger fires only on the server's triggerCharacters (e.g. '.'), so extend to
            -- every printable key: plain typing pops the menu (see :h lsp-attach)
            local provider = client.server_capabilities.completionProvider
            if provider then
              local chars = {}
              for i = 32, 126 do
                chars[#chars + 1] = string.char(i)
              end
              provider.triggerCharacters = chars
            end
            vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
          end

          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = '',
              [vim.diagnostic.severity.WARN]  = '',
              [vim.diagnostic.severity.INFO]  = '',
              [vim.diagnostic.severity.HINT]  = '',
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      -- Plain capabilities: no snippet engine installed, so servers send plain text completions
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = false

      local original_servers_table = {
        prismals = {},
        tailwindcss = {},
        lemminx = {},
        -- Use nvim-lspconfig's Angular command builder. It discovers the
        -- project and Mason node_modules probe paths, including Angular's
        -- language-server dependencies.
        angularls = {},
        ts_ls = {},
        gopls = {},
        cssls = {},
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim", "require" } },
              workspace = { library = vim.api.nvim_get_runtime_file("", true) },
              telemetry = { enable = false },
            },
          },
        },
        rust_analyzer = {}
      }

      for key, value in pairs(original_servers_table) do
        value.capabilities = capabilities
        vim.lsp.config(key, value)
      end
      vim.lsp.enable(vim.tbl_keys(original_servers_table))
    end
  },
  {
    "andreshazard/vim-freemarker",
    config = function() return {} end
  }
}
