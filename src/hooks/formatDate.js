export const formatCreatedAt = (createdAt) => {
  const date = new Date(createdAt?.seconds * 1000);
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
};
