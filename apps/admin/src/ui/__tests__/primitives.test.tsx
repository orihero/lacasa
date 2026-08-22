/**
 * The primitives' contracts, not their looks.
 *
 * Everything asserted here is something a screen's test selects on or a
 * decision PRECEDENCE.md calls load-bearing: the accessible names on controls
 * that change someone else's account, `aria-pressed` on the filters,
 * a dialog that cannot be escaped mid-flight and never opens with confirm under
 * the cursor, the skeleton's row × column counts, and the error layer that
 * apps/web's design contract would have deleted.
 */
import { ThemeProvider } from "@mui/material/styles";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactElement } from "react";
import { describe, expect, it, vi } from "vitest";
import "@/i18n";
import { theme } from "@/theme";
import { Avatar } from "../Avatar";
import { ConfirmDialog } from "../ConfirmDialog";
import { Field, Input } from "../Field";
import { FilterChip } from "../FilterChip";
import { LoadMore } from "../LoadMore";
import { Panel, PanelHead } from "../Panel";
import { Seg } from "../Seg";
import { EmptyState, ErrorState, LoadingState, Notice, TableSkeleton } from "../States";
import { RowAction, Table } from "../Table";
import { Tag } from "../Tag";

function renderUi(ui: ReactElement) {
  return render(<ThemeProvider theme={theme}>{ui}</ThemeProvider>);
}

describe("Tag", () => {
  it("renders its label verbatim, with no capitalisation of the audit types", () => {
    renderUi(<Tag tone="err">olx.crosspost_aborted</Tag>);
    expect(screen.getByText("olx.crosspost_aborted")).toBeInTheDocument();
  });
});

describe("Seg", () => {
  it("is a named group of buttons carrying aria-pressed", async () => {
    const user = userEvent.setup();
    const onChange = vi.fn();
    renderUi(
      <Seg
        label="Application status"
        value="pending"
        onChange={onChange}
        options={[
          { value: "pending", label: "Pending" },
          { value: "approved", label: "Approved" },
        ]}
      />,
    );

    expect(screen.getByRole("group", { name: "Application status" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Pending" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );

    await user.click(screen.getByRole("button", { name: "Approved" }));
    expect(onChange).toHaveBeenCalledWith("approved");
  });
});

describe("FilterChip", () => {
  it("is a real button only when it does something", async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    const { rerender } = renderUi(
      <FilterChip active onClick={onClick}>
        Agent: Dilnoza
      </FilterChip>,
    );

    const chip = screen.getByRole("button", { name: "Agent: Dilnoza" });
    expect(chip).toHaveAttribute("aria-pressed", "true");
    await user.click(chip);
    expect(onClick).toHaveBeenCalledTimes(1);

    rerender(
      <ThemeProvider theme={theme}>
        <FilterChip>Any realtor status</FilterChip>
      </ThemeProvider>,
    );
    expect(screen.queryByRole("button", { name: "Any realtor status" })).toBeNull();
    expect(screen.getByText("Any realtor status")).toBeInTheDocument();
  });
});

describe("RowAction", () => {
  it("announces the row it acts on, even with visible text beside the glyph", () => {
    renderUi(
      <RowAction icon={() => null} label="Approve Dilnoza Yusupova" tone="ok">
        Approve
      </RowAction>,
    );
    expect(
      screen.getByRole("button", { name: "Approve Dilnoza Yusupova" }),
    ).toBeInTheDocument();
  });
});

describe("ConfirmDialog", () => {
  function decision(props: Partial<Parameters<typeof ConfirmDialog>[0]> = {}) {
    return (
      <ConfirmDialog
        title="Approve realtor application"
        subject="dilnoza@example.com"
        consequence="Approving grants agent access."
        confirmLabel="Approve"
        onConfirm={vi.fn()}
        onCancel={vi.fn()}
        {...props}
      />
    );
  }

  it("takes its accessible name from the title and does not focus confirm", () => {
    renderUi(decision());

    expect(
      screen.getByRole("dialog", { name: "Approve realtor application" }),
    ).toBeInTheDocument();
    // A dialog that opens with "Approve" under the Enter key is a dialog that
    // gets confirmed by the keystroke that opened it.
    expect(screen.getByRole("button", { name: "Approve" })).not.toHaveFocus();
  });

  it("cancels on Escape while idle", async () => {
    const user = userEvent.setup();
    const onCancel = vi.fn();
    renderUi(decision({ onCancel }));

    await user.keyboard("{Escape}");
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it("cannot be dismissed while the mutation is in flight", async () => {
    const user = userEvent.setup();
    const onCancel = vi.fn();
    renderUi(decision({ busy: true, onCancel }));

    expect(screen.getByRole("button", { name: "Working…" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Cancel" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Close" })).toBeDisabled();

    await user.keyboard("{Escape}");
    expect(onCancel).not.toHaveBeenCalled();
  });

  it("surfaces the mutation's own error as an alert", () => {
    renderUi(decision({ error: "This application was already decided." }));
    expect(screen.getByRole("alert")).toHaveTextContent(
      "This application was already decided.",
    );
  });
});

describe("States", () => {
  it("announces loading with its own label", () => {
    renderUi(<LoadingState label="Checking your session…" />);
    expect(screen.getByRole("status")).toHaveTextContent("Checking your session…");
  });

  it("keeps the empty state's second line, and neither line is a heading", () => {
    renderUi(<EmptyState title="The queue is clear" sub="No realtor application is waiting." />);

    expect(screen.getByText("The queue is clear")).toBeInTheDocument();
    expect(screen.getByText("No realtor application is waiting.")).toBeInTheDocument();
    expect(screen.queryByRole("heading")).toBeNull();
  });

  it("shows the server's real message, its raw code, and a retry", async () => {
    const user = userEvent.setup();
    const onRetry = vi.fn();
    renderUi(
      <ErrorState
        error={{ code: "not_pending", message: "This application was already decided." }}
        onRetry={onRetry}
      />,
    );

    const alert = screen.getByRole("alert");
    expect(alert).toHaveTextContent("This application was already decided.");
    expect(alert).toHaveTextContent("not_pending");

    await user.click(screen.getByRole("button", { name: "Try again" }));
    expect(onRetry).toHaveBeenCalledTimes(1);
  });

  it("falls back to a literal message when the thrown value carries none", () => {
    renderUi(<ErrorState error={42} />);
    expect(screen.getByRole("alert")).toHaveTextContent("Something went wrong.");
  });

  it("draws the skeleton at the row and column count the screen asks for", () => {
    renderUi(
      <Table>
        <TableSkeleton rows={8} cols={5} />
      </Table>,
    );

    expect(screen.getAllByRole("row")).toHaveLength(8);
    expect(screen.getAllByRole("cell")).toHaveLength(40);
  });
});

describe("LoadMore", () => {
  it("says how many are loaded and offers the next page", async () => {
    const user = userEvent.setup();
    const onLoadMore = vi.fn();
    const { rerender } = renderUi(
      <LoadMore loaded={24} hasMore onLoadMore={onLoadMore} noun="accounts" />,
    );

    expect(screen.getByText(/24/)).toBeInTheDocument();
    expect(screen.getByText(/accounts loaded/)).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "Load more" }));
    expect(onLoadMore).toHaveBeenCalledTimes(1);

    // The count survives the last page — "24 accounts" and "24 accounts
    // loaded" are different facts.
    rerender(
      <ThemeProvider theme={theme}>
        <LoadMore loaded={24} hasMore={false} onLoadMore={onLoadMore} noun="accounts" />
      </ThemeProvider>,
    );
    expect(screen.getByText("End of list")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Load more" })).toBeNull();
  });
});

describe("Panel and Field", () => {
  it("titles a panel with an h2 — the h1 belongs to the topbar", () => {
    renderUi(
      <Panel>
        <PanelHead title="User directory" sub="Role is what an account can do." />
      </Panel>,
    );

    expect(screen.getByRole("heading", { level: 2, name: "User directory" })).toBeInTheDocument();
  });

  it("associates a field's label with its control implicitly", async () => {
    const user = userEvent.setup();
    renderUi(
      <Field label="Email" hint="The account you sign in with.">
        <Input type="email" autoComplete="email" />
      </Field>,
    );

    const input = screen.getByLabelText("Email");
    await user.type(input, "dilnoza@example.com");
    expect(input).toHaveValue("dilnoza@example.com");
  });

  it("states a consequence above the controls that cause it", () => {
    renderUi(
      <Notice tone="danger" title="Approving promotes the account from Buyer to Agent.">
        It cannot be silently undone.
      </Notice>,
    );

    expect(
      screen.getByText("Approving promotes the account from Buyer to Agent."),
    ).toBeInTheDocument();
    expect(screen.getByText("It cannot be silently undone.")).toBeInTheDocument();
  });
});

describe("Avatar", () => {
  it("falls back to a named initials chip rather than a nameless graphic", () => {
    renderUi(<Avatar name="Dilnoza Yusupova" round />);
    const chip = screen.getByRole("img", { name: "Dilnoza Yusupova" });
    expect(chip).toHaveTextContent("DY");
  });
});
