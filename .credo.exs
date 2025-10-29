# .credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      strict: false,
      color: true,
      checks: %{
        enabled: [
          # Consistency - let Elixir formatter handle most of this
          {Credo.Check.Consistency.ExceptionNames, []},

          # Design - minimal pragmatic checks
          {Credo.Check.Design.TagTODO, [exit_status: 0]},
          {Credo.Check.Design.TagFIXME, [exit_status: 0]},

          # Readability - only essential checks
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.LargeNumbers, [only_greater_than: 99_999]},

          # Refactoring - only important complexity warnings
          {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 15]},
          {Credo.Check.Refactor.Nesting, [max_nesting: 4]},
          {Credo.Check.Refactor.FunctionArity, [max_arity: 8]},

          # Warnings - security and correctness issues only
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.Dbg, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.UnsafeExec, []},
          {Credo.Check.Warning.UnsafeToAtom, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []}
        ],
        disabled: [
          # Let formatter handle style
          {Credo.Check.Readability.MaxLineLength, []},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
          {Credo.Check.Readability.SinglePipe, []},
          {Credo.Check.Readability.StrictModuleLayout, []},

          # Too opinionated for this project
          {Credo.Check.Refactor.PipeChainStart, []},
          {Credo.Check.Refactor.AppendSingleItem, []},
          {Credo.Check.Refactor.CondStatements, []},
          {Credo.Check.Refactor.RedundantWithClauseResult, []},
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.DuplicatedCode, []}
        ]
      }
    }
  ]
}
