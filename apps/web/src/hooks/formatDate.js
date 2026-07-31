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

// export const getTimeIntervals = () => {
//   const now = new Date();
//   let startTime = new Date();
//   startTime.setHours(0, 0, 0, 0);

//   const intervals = [];
//   while (startTime <= now) {
//     intervals.push(startTime.toTimeString().slice(0, 5));
//     startTime.setHours(startTime.getHours() + 2);
//   }

//   const nearestTime = new Date(startTime);
//   if (nearestTime < now) {
//     intervals.push(nearestTime.toTimeString().slice(0, 5));
//   }

//   return intervals;
// };

export const getTimeIntervals = (type) => {
  const now = new Date();
  let startTime;
  const endTime = new Date();

  const intervals = [];

  if (type === "thisMonth") {
    startTime = new Date(now.getFullYear(), now.getMonth(), 1);
    while (startTime <= endTime) {
      intervals.push(startTime.toISOString().slice(0, 10));
      startTime.setDate(startTime.getDate() + 1);
    }
  } else if (type === "thisWeek") {
    const dayOfWeek = now.getDay();
    const monday = new Date(now);
    monday.setDate(now.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1) + 1);
    monday.setHours(0, 0, 0, 0);
    startTime = new Date(monday);
    while (startTime.getTime() <= endTime.getTime()) {
      intervals.push(startTime.toISOString().slice(0, 10));
      startTime.setDate(startTime.getDate() + 1);
    }
  } else if (type === "today" || type === "all") {
    startTime = new Date();
    startTime.setHours(0, 0, 0, 0);
    while (startTime <= endTime) {
      intervals.push(startTime.toTimeString().slice(0, 5));
      startTime.setHours(startTime.getHours() + 2);
    }
  } else {
    throw new Error(
      "Noto'g'ri type qiymati. Faqat 'thisMonth', 'thisWeek' yoki 'today' bo'lishi kerak.",
    );
  }

  return intervals;
};

export const generateRandomData = (timeArray) => {
  const getRandomNumber = (min, max) =>
    Math.floor(Math.random() * (max - min + 1)) + min;

  return timeArray.map((time) => ({
    name: time,
    create: getRandomNumber(10, 50),
    sold: getRandomNumber(10, 100),
  }));
};
