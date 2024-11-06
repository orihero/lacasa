export const formatCreatedAt = (createdAt) => {
  const date = new Date(createdAt?.seconds * 1000);
  return date
    .toLocaleString("en-GB", {
      hour: "2-digit",
      minute: "2-digit",
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    })
    .replace(",", " |");
};
