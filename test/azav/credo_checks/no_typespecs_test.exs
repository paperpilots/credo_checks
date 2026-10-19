defmodule Azav.CredoChecks.NoTypespecsTest do
  use Credo.Test.Case

  alias Azav.CredoChecks.NoTypespecs

  setup_all do
    {:ok, _} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags @type, @typep, @opaque, and @spec" do
    """
    defmodule Sample do
      @type id :: integer()
      @typep secret :: binary()
      @opaque token :: binary()

      @spec fetch(id()) :: token()
      def fetch(_id), do: nil
    end
    """
    |> to_source_file()
    |> run_check(NoTypespecs)
    |> assert_issues(fn issues ->
      assert issues |> Enum.map(&{&1.line_no, &1.trigger}) |> Enum.sort() == [
               {2, "@type"},
               {3, "@typep"},
               {4, "@opaque"},
               {6, "@spec"}
             ]
    end)
  end

  test "ignores other attributes" do
    """
    defmodule Sample do
      @moduledoc "A sample."

      @timeout 5_000

      @impl true
      def init(state), do: {:ok, state}

      @doc "Returns the timeout."
      def timeout, do: @timeout
    end
    """
    |> to_source_file()
    |> run_check(NoTypespecs)
    |> refute_issues()
  end
end
