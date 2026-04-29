defmodule Azav.CredoChecks.UnescapedTenantPrefixTest do
  use Credo.Test.Case

  alias Azav.CredoChecks.UnescapedTenantPrefix

  setup_all do
    {:ok, _} = Application.ensure_all_started(:credo)
    :ok
  end

  test "passes when prefix() is wrapped in double quotes" do
    """
    defmodule Sample do
      def change do
        execute("ALTER TABLE \\"\#{prefix()}\\".users ADD COLUMN foo text")
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> refute_issues()
  end

  test "passes for heredoc with quoted prefix interpolation" do
    """
    defmodule Sample do
      def change do
        execute(\"\"\"
        UPDATE \\"\#{prefix()}\\".coaching_sessions
        SET participant_id = NULL
        \"\"\")
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> refute_issues()
  end

  test "passes for sigil with quoted prefix interpolation" do
    """
    defmodule Sample do
      def change do
        execute(~s|ALTER TABLE "\#{prefix()}".users ADD COLUMN foo text|)
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> refute_issues()
  end

  test "flags unquoted prefix interpolation" do
    """
    defmodule Sample do
      def change do
        execute("ALTER TABLE \#{prefix()}.users ADD COLUMN foo text")
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> assert_issue()
  end

  test "flags when only the left quote is present" do
    """
    defmodule Sample do
      def change do
        execute("ALTER TABLE \\"\#{prefix()}.users ADD COLUMN foo text")
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> assert_issue()
  end

  test "flags when only the right quote is present" do
    """
    defmodule Sample do
      def change do
        execute("ALTER TABLE \#{prefix()}\\".users ADD COLUMN foo text")
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> assert_issue()
  end

  test "ignores interpolations that don't call prefix()" do
    """
    defmodule Sample do
      def change do
        table = "users"
        execute("ALTER TABLE \#{table} ADD COLUMN foo text")
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> refute_issues()
  end

  test "ignores bare prefix() calls outside strings" do
    """
    defmodule Sample do
      def change do
        create table(:users, prefix: prefix()) do
          add :name, :string
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(UnescapedTenantPrefix)
    |> refute_issues()
  end
end
