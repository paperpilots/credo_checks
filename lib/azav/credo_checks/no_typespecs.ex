defmodule Azav.CredoChecks.NoTypespecs do
  @moduledoc """
  Flags `@spec`, `@type`, `@typep`, and `@opaque`.
  """

  use Credo.Check,
    base_priority: :high,
    category: :readability,
    explanations: [
      check: """
      This codebase does not use typespecs. Remove `@spec`, `@type`,
      `@typep`, and `@opaque`.

          # bad
          @spec add(integer(), integer()) :: integer()
          def add(a, b), do: a + b

          # good
          def add(a, b), do: a + b
      """
    ]

  @typespec_attributes [:spec, :type, :typep, :opaque]

  @impl Credo.Check
  def run(%Credo.SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, meta, [{attr, _, _}]} = ast, issues, issue_meta)
       when attr in @typespec_attributes do
    issue =
      format_issue(issue_meta,
        message: "Typespecs are not allowed. Remove `@#{attr}`.",
        line_no: meta[:line],
        trigger: "@#{attr}"
      )

    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}
end
