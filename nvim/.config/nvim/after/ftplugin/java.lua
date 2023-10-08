local config = {
    cmd = {
        vim.fn.stdpath("data") ..
        "/mason/packages/jdtls/bin/jdtls",
    },
    root_dir = require('jdtls.setup').find_root({
        'build.xml',           -- Ant
        'pom.xml',             -- Maven
        'settings.gradle',     -- Gradle
        'settings.gradle.kts', -- Gradle
    } or vim.fn.getcwd()),
    settings = {
        java = {
        }
    },
    init_options = {
        bundles = {
            vim.fn.stdpath("data") ..
            "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-0.47.0.jar",
        },
    },
}

config['on_attach'] = function(client, bufnr)
    require('jdtls').setup_dap({ hotcodereplace = 'auto' })
    require('jdtls.dap').setup_dap_main_class_configs()
end

-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.

require('jdtls').start_or_attach(config)
