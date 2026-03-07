# .credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      strict: true,
      color: true,
      checks: %{
        enabled: [
          #
          # ━━━ Consistency ━━━
          #
          # Enforce coding style consistency across the codebase.
          # Formatter-handled checks (LineEndings, SpaceAroundOperators,
          # SpaceInParentheses, TabsOrSpaces) are excluded as redundant.
          #
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.MultiAliasImportRequireUse, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.UnusedVariableNames, [force: :anonymous]},

          #
          # ━━━ Design ━━━
          #
          # Architectural and code design checks.
          #
          {Credo.Check.Design.TagTODO, [exit_status: 0]},
          {Credo.Check.Design.TagFIXME, [exit_status: 2]},
          {Credo.Check.Design.SkipTestWithoutComment, []},

          #
          # ━━━ Readability ━━━
          #
          # Code readability and documentation quality.
          #
          {Credo.Check.Readability.AliasOrder, []},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.ImplTrue, []},
          {Credo.Check.Readability.LargeNumbers, [only_greater_than: 99_999]},
          {Credo.Check.Readability.ModuleAttributeNames, []},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, [max_blank_lines: 2]},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SeparateAliasRequire, []},
          {Credo.Check.Readability.Specs, [include_defp: false]},
          {Credo.Check.Readability.StringSigils, [maximum_allowed_quotes: 3]},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Readability.WithCustomTaggedTuple, []},
          {Credo.Check.Readability.WithSingleClause, []},

          #
          # ━━━ Refactor ━━━
          #
          # Code quality and complexity checks with tightened thresholds.
          #
          {Credo.Check.Refactor.AppendSingleItem, []},
          {Credo.Check.Refactor.CondStatements, []},
          {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 9]},
          {Credo.Check.Refactor.DoubleBooleanNegation, []},
          {Credo.Check.Refactor.FilterCount, []},
          {Credo.Check.Refactor.FilterFilter, []},
          {Credo.Check.Refactor.FilterReject, []},
          {Credo.Check.Refactor.FunctionArity, [max_arity: 6]},
          {Credo.Check.Refactor.MapJoin, []},
          {Credo.Check.Refactor.MapMap, []},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          {Credo.Check.Refactor.NegatedIsNil, []},
          {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
          {Credo.Check.Refactor.PerceivedComplexity, [max_complexity: 9]},
          {Credo.Check.Refactor.RejectFilter, []},
          {Credo.Check.Refactor.RejectReject, []},
          {Credo.Check.Refactor.UnlessWithElse, []},
          {Credo.Check.Refactor.WithClauses, []},

          #
          # ━━━ Warning ━━━
          #
          # Potential bugs, security issues, and antipatterns.
          #
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.Dbg, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.ForbiddenModule, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.MapGetUnsafePass, []},
          {Credo.Check.Warning.MixEnv, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.SpecWithStruct, []},
          {Credo.Check.Warning.StructFieldAmount, [max_fields: 31]},
          {Credo.Check.Warning.UnsafeExec, []},
          {Credo.Check.Warning.UnsafeToAtom, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedMapOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []},
          {Credo.Check.Warning.WrongTestFileExtension, []}
        ],
        disabled: [
          #
          # ━━━ Formatter-handled (redundant with mix format) ━━━
          #
          {Credo.Check.Consistency.LineEndings, "formatter handles this"},
          {Credo.Check.Consistency.SpaceAroundOperators, "formatter handles this"},
          {Credo.Check.Consistency.SpaceInParentheses, "formatter handles this"},
          {Credo.Check.Consistency.TabsOrSpaces, "formatter handles this"},
          {Credo.Check.Readability.MaxLineLength, "formatter handles this"},
          {Credo.Check.Readability.OnePipePerLine, "formatter handles this"},
          {Credo.Check.Readability.ParenthesesInCondition, "formatter handles this"},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, "formatter handles this"},
          {Credo.Check.Readability.SinglePipe, "formatter handles this"},
          {Credo.Check.Readability.SpaceAfterCommas, "formatter handles this"},

          #
          # ━━━ Incompatible with Elixir >= 1.7 ━━━
          #
          {Credo.Check.Readability.PreferUnquotedAtoms, "requires Elixir < 1.7.0-dev"},
          {Credo.Check.Warning.LazyLogging, "requires Elixir < 1.7.0"},

          #
          # ━━━ Not suitable for shared-state tests ━━━
          #
          {Credo.Check.Refactor.PassAsyncInTestCases,
           "many tests share ETS state and cannot run async"},

          #
          # ━━━ Too opinionated for this project ━━━
          #
          {Credo.Check.Design.AliasUsage, "forces aliasing on single-use modules"},
          {Credo.Check.Design.DuplicatedCode, "high false-positive rate"},
          {Credo.Check.Readability.AliasAs, "rarely needed"},
          {Credo.Check.Readability.BlockPipe, "conflicts with common patterns"},
          {Credo.Check.Readability.MultiAlias, "team preference varies"},
          {Credo.Check.Readability.NestedFunctionCalls, "too aggressive"},
          {Credo.Check.Readability.OneArityFunctionInPipe, "conflicts with pipe style"},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, "valid in transforms"},
          {Credo.Check.Readability.SingleFunctionToBlockPipe, "stylistic preference"},
          {Credo.Check.Readability.StrictModuleLayout, "too rigid for protocol impls"},
          {Credo.Check.Refactor.ABCSize, "overlaps with cyclomatic/perceived complexity"},
          {Credo.Check.Refactor.Apply, "valid for dynamic dispatch"},
          {Credo.Check.Refactor.CaseTrivialMatches, "pattern matching is idiomatic"},
          {Credo.Check.Refactor.IoPuts, "useful in CLI module"},
          {Credo.Check.Refactor.LongQuoteBlocks, "needed for large mapping tables"},
          {Credo.Check.Refactor.MapInto, "rarely applicable"},
          {Credo.Check.Refactor.MatchInCondition, "valid in guards"},
          {Credo.Check.Refactor.ModuleDependencies, "too restrictive for lib internals"},
          {Credo.Check.Refactor.PipeChainStart, "conflicts with common patterns"},
          {Credo.Check.Refactor.RedundantWithClauseResult, "used in validation chains"},
          {Credo.Check.Refactor.UtcNowTruncate, "no DateTime usage"},
          {Credo.Check.Refactor.VariableRebinding, "idiomatic in pipelines"},

          #
          # ━━━ Not applicable to this project ━━━
          #
          {Credo.Check.Warning.ApplicationConfigInModuleAttribute,
           "no Application.get_env in module attributes"},
          {Credo.Check.Warning.LeakyEnvironment, "no System.cmd usage"},
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig,
           "no Logger metadata configuration"}
        ]
      }
    }
  ]
}
