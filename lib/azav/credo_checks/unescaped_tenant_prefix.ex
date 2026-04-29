defmodule Azav.CredoChecks.UnescapedTenantPrefix do
  @moduledoc """
  Flags interpolations of `prefix/0` (Triplex tenant schema) in raw SQL
  strings that aren't wrapped in double quotes.

  Tenant slugs may begin with a digit (`111corp`) or contain hyphens
  (`my-org`); Postgres rejects those as bare identifiers, so every
  interpolation must be quoted: `"\#{prefix()}".table`.
  """

  use Credo.Check,
    base_priority: :higher,
    category: :warning,
    exit_status: 32,
    explanations: [
      check: """
      Tenant prefixes returned by Triplex's `prefix/0` can contain leading
      digits or hyphens (e.g. `111corp`, `my-org`). Postgres rejects those
      as bare SQL identifiers, so every `\#{prefix()}` interpolation must be
      wrapped in double quotes.

          # bad — explodes for "111corp" or "my-org"
          execute("ALTER TABLE \#{prefix()}.users ADD COLUMN ...")

          # good
          execute(~s|ALTER TABLE "\#{prefix()}".users ADD COLUMN ...|)
      """
    ]

  @impl Credo.Check
  def run(%Credo.SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:<<>>, _, parts} = ast, issues, issue_meta) when is_list(parts) do
    {ast, scan(parts, issue_meta) ++ issues}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp scan(parts, issue_meta) do
    parts
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {{:"::", _, [{{:., _, [Kernel, :to_string]}, meta, [expr]}, _]}, index} ->
        if calls_prefix?(expr) and not wrapped_in_quotes?(parts, index) do
          [
            format_issue(issue_meta,
              message:
                "Wrap `\#{prefix()}` in double quotes — tenant slugs with leading digits or hyphens break unquoted SQL identifiers.",
              line_no: meta[:line],
              trigger: "prefix()"
            )
          ]
        else
          []
        end

      _ ->
        []
    end)
  end

  defp calls_prefix?(ast) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {:prefix, _, []} = node, _acc -> {node, true}
        node, acc -> {node, acc}
      end)

    found?
  end

  defp wrapped_in_quotes?(parts, index) when index > 0 do
    left = Enum.at(parts, index - 1)
    right = Enum.at(parts, index + 1)

    is_binary(left) and String.ends_with?(left, "\"") and
      is_binary(right) and String.starts_with?(right, "\"")
  end

  defp wrapped_in_quotes?(_parts, _index), do: false
end
