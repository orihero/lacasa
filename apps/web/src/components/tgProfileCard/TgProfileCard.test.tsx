// TgProfileCard's `data` only ever carries `id` now (see services/tg.ts's
// file header — the old getChat/getChatMembersCount/getFile enrichment was
// removed with the bot token, and the server has no replacement endpoint).
// This proves the card renders an honest "unavailable" state for the
// missing fields instead of fabricating a title/username/avatar/count.
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import TgProfileCard from "./TgProfileCard";

describe("TgProfileCard", () => {
  it("renders honest placeholders when only `id` is known (the current, always-true case)", () => {
    const { container } = render(<TgProfileCard data={{ id: 111 }} />);

    expect(screen.getByText("Telegram channel")).toBeInTheDocument();
    expect(screen.getByText("Chat 111")).toBeInTheDocument();
    expect(screen.getByText("Channel details unavailable")).toBeInTheDocument();
    // No fabricated avatar url: the placeholder div renders, not an <img>.
    expect(container.querySelector(".tg-avatar-placeholder")).toBeInTheDocument();
    expect(container.querySelector("img.tg-avatar")).not.toBeInTheDocument();
  });

  it("still displays real data if it were ever supplied, rather than always forcing the placeholder", () => {
    render(
      <TgProfileCard
        data={{ id: 111, title: "La Casa", username: "lacasa", file_path: "https://cdn.example.com/a.jpg", members_count: 42 }}
      />,
    );

    expect(screen.getByText("La Casa")).toBeInTheDocument();
    expect(screen.getByText("@lacasa")).toBeInTheDocument();
    expect(screen.getByText("42")).toBeInTheDocument();
    expect(screen.queryByText("Channel details unavailable")).not.toBeInTheDocument();
  });
});
