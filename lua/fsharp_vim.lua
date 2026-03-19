-- port of refactored fsharp.vim to lua
-- only neovim 0.12+ is supported

local M = {}

M.config_keys = {
  { vim = "automatic_workspace_init",                         fsac = "AutomaticWorkspaceInit",                      default = true },
  { vim = "workspace_mode_peek_deep_level",                   fsac = "WorkspaceModePeekDeepLevel",                  default = 2 },
  { vim = "exclude_project_directories",                      fsac = "ExcludeProjectDirectories",                   default = {} },
  { vim = "keywords_autocomplete",                            fsac = "keywordsAutocomplete",                        default = true },
  { vim = "external_autocomplete",                            fsac = "ExternalAutocomplete",                        default = false },
  { vim = "full_name_external_autocomplete",                  fsac = "FullNameExternalAutocomplete",                default = false },
  { vim = "linter",                                           fsac = "Linter",                                      default = true },
  { vim = "linter_config",                                    fsac = "LinterConfig" },
  { vim = "indentation_size",                                 fsac = "IndentationSize",                             default = 4 },
  { vim = "union_case_stub_generation",                       fsac = "UnionCaseStubGeneration",                     default = true },
  { vim = "union_case_stub_generation_body",                  fsac = "UnionCaseStubGenerationBody" },
  { vim = "record_stub_generation",                           fsac = "RecordStubGeneration",                        default = true },
  { vim = "record_stub_generation_body",                      fsac = "RecordStubGenerationBody" },
  { vim = "interface_stub_generation",                        fsac = "InterfaceStubGeneration",                     default = true },
  { vim = "interface_stub_generation_object_identifier",      fsac = "InterfaceStubGenerationObjectIdentifier",     default = "this" },
  { vim = "interface_stub_generation_method_body",            fsac = "InterfaceStubGenerationMethodBody" },
  { vim = "add_private_access_modifier",                      fsac = "AddPrivateAccessModifier",                    default = false },
  { vim = "unused_opens_analyzer",                            fsac = "UnusedOpensAnalyzer",                         default = true },
  { vim = "unused_opens_analyzer_exclusions",                 fsac = "UnusedOpensAnalyzerExclusions",               default = {} },
  { vim = "unused_declarations_analyzer",                     fsac = "UnusedDeclarationsAnalyzer",                  default = true },
  { vim = "unused_declarations_analyzer_exclusions",          fsac = "UnusedDeclarationsAnalyzerExclusions",        default = {} },
  { vim = "simplify_name_analyzer",                           fsac = "SimplifyNameAnalyzer",                        default = false },
  { vim = "simplify_name_analyzer_exclusions",                fsac = "SimplifyNameAnalyzerExclusions",              default = {} },
  { vim = "unnecessary_parentheses_analyzer",                 fsac = "UnnecessaryParenthesesAnalyzer",              default = false },
  { vim = "unnecessary_parentheses_analyzer_exclusions",      fsac = "UnnecessaryParenthesesAnalyzerExclusions",    default = {} },
  { vim = "resolve_namespaces",                               fsac = "ResolveNamespaces",                           default = true },
  { vim = "enable_reference_code_lens",                       fsac = "EnableReferenceCodeLens",                     default = true },
  { vim = "enable_analyzers",                                 fsac = "EnableAnalyzers",                             default = false },
  { vim = "analyzers_path",                                   fsac = "AnalyzersPath" },
  { vim = "exclude_analyzers",                                fsac = "ExcludeAnalyzers" },
  { vim = "include_analyzers",                                fsac = "IncludeAnalyzers" },
  { vim = "disable_in_memory_project_references",             fsac = "DisableInMemoryProjectReferences",            default = false },
  { vim = "line_lens",                                        fsac = "LineLens",                                    default = { enabled = "never", prefix = "" } },
  { vim = "use_sdk_scripts",                                  fsac = "UseSdkScripts",                               default = true },
  { vim = "dot_net_root",                                     fsac = "dotNetRoot" },
  { vim = "fsi_extra_parameters",                             fsac = "fsiExtraParameters" },
  { vim = "fsi_extra_interactive_parameters",                 fsac = "fsiExtraInteractiveParameters",               default = { "--readline-" } },
  { vim = "fsi_extra_shared_parameters",                      fsac = "fsiExtraSharedParameters",                    default = {} },
  { vim = "fsi_compiler_tool_locations",                      fsac = "fsiCompilerToolLocations",                    default = {} },
  { vim = "tooltip_mode",                                     fsac = "TooltipMode",                                 default = "full" },
  { vim = "generate_binlog",                                  fsac = "GenerateBinlog",                              default = false },
  { vim = "abstract_class_stub_generation",                   fsac = "AbstractClassStubGeneration",                 default = true },
  { vim = "abstract_class_stub_generation_object_identifier", fsac = "AbstractClassStubGenerationObjectIdentifier", default = "this" },
  { vim = "abstract_class_stub_generation_method_body",       fsac = "AbstractClassStubGenerationMethodBody",       default = 'failwith "Not Implemented"' },
  -- "\    {'key': 'CodeLenses', TODO},
  -- "\    {'key': 'PipelineHints', TODO}
  -- "\    {'key': 'InlayHints', TODO}
  -- "\    {'key': 'Fsac', TODO}
  -- "\    {'key': 'Notifications', TODO}
  -- "\    {'key': 'Debug', TODO}
}

function M.notify(method, params)
  require("ionide").notify(method, params)
end

function M.hover()
  vim.lsp.buf.hover()
end

function M.call(method, params, key)
  require("ionide").call(method, params, key)
end

function M.text_document_identifier(path)
  return { Uri = vim.uri_from_fname(vim.fn.fnamemodify(path, ":p")), }
end

function M.position(line, character)
  return { Line = line, Character = character }
end

function M.text_document_position_params(document_uri, line, character)
  return {
    TextDocument = M.text_document_identifier(document_uri),
    Position = M.position(line, character),
  }
end

function M.workspace_load_params(files)
  local docs = {}
  for i, file in ipairs(files) do
    docs[i] = M.text_document_identifier(file)
  end
  return { TextDocuments = docs }
end

function M.get_server_config()
  local fsharp = {}
  local use_defaults = vim.g["fsharp#use_recommended_server_config"]

  for _, key in ipairs(M.config_keys) do
    -- what the user gave in the configuration
    local value = vim.g["fsharp#" .. key.vim]

    if value ~= nil then
      -- send what the user gave in key.vim to FSAC, but in fsac format
      fsharp[key.fsac] = value
    elseif use_defaults and key.default ~= nil then
      -- send the defaults to FSAC, in fsac format
      fsharp[key.fsac] = key.default
    end
  end

  return fsharp
end

function M.update_server_config()
  M.notify(
    'workspace/didChangeConfiguration',
    { settings = { Fsharp = M.get_server_config() } }
  )
end

return M

-- function M.get_server_config(config)
--   local fsharp = {}
--
--   for _, key in ipairs(M.config_keys) do
--     local value = config[key.vim]
--     if value ~= nil then
--       fsharp[key.fsac] = value
--     elseif config.use_recommended_server_config and key.default ~= nil then
--       fsharp[key.fsac] = key.default
--     end
--   end
--
--   return fsharp
-- end

-- -- function M.to_snake_case(str)
-- --   return str
-- --       :gsub("(%u)(%u%l)", "%1_%2") -- ABc -> a_bc
-- --       :gsub("(%l)(%u)", "%1_%2")   -- aB  -> a_b
-- --       :lower()
-- -- end
-- function M.get_server_config()
--   local fsharp = {}
--
--   for _, key in ipairs(M.config_keys) do
--     -- local vim_key = "fsharp#" .. key.vim
--     -- local fsac_key = "fsharp#" .. key.fsac
--
--     if vim.g[key.vim] ~= nil then
--       fsharp[key.fsac] = vim.g["fsharp#" .. key.vim]
--     elseif vim.g["fsharp#" .. key.fsac] ~= nil then
--       fsharp[key.fsac] = vim.g["fsharp#" .. key.fsac]
--     elseif key.default ~= nil and vim.g["fsharp#use_recommended_server_config"] then
--       vim.g["fsharp#" .. key.vim] = key.default
--       fsharp[key.fsac] = key.default
--     end
--   end
--
--   return fsharp
-- end

-- vim.notify("fsharp_vim.call -> " .. "hello") -- temporary side effect for testing only
