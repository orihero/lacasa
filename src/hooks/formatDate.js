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
    .replace(",", " | ")
    .replaceAll("/", ".");
};
export const formatCallbackDate = (callbackDate) => {
  return new Date(callbackDate).toLocaleString("en-GB", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
};

export const getTimeIntervals = () => {
  const now = new Date();
  let startTime = new Date();
  startTime.setHours(0, 0, 0, 0);

  const intervals = [];
  while (startTime <= now) {
    intervals.push(startTime.toTimeString().slice(0, 5));
    startTime.setHours(startTime.getHours() + 2);
  }

  const nearestTime = new Date(startTime);
  if (nearestTime < now) {
    intervals.push(nearestTime.toTimeString().slice(0, 5));
  }

  return intervals;
};

export const generateRandomData = (timeArray) => {
  const getRandomNumber = (min, max) =>
    Math.floor(Math.random() * (max - min + 1)) + min;

  return timeArray.map((time) => ({
    name: time,
    uv: getRandomNumber(10, 50),
    pv: getRandomNumber(10, 100),
    amt: getRandomNumber(20, 30),
  }));
};
