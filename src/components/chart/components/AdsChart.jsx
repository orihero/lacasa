import React from "react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  generateRandomData,
  getTimeIntervals,
} from "../../../hooks/formatDate";
const data = [
  {
    name: "09:00",
    uv: 40,
    pv: 24,
    amt: 24,
  },
  {
    name: "10:00",
    uv: 30,
    pv: 13,
    amt: 22,
  },
  {
    name: "Page C",
    uv: 20,
    pv: 98,
    amt: 22,
  },
  {
    name: "Page D",
    uv: 27,
    pv: 39,
    amt: 20,
  },
  {
    name: "Page E",
    uv: 18,
    pv: 48,
    amt: 21,
  },
  {
    name: "Page F",
    uv: 23,
    pv: 38,
    amt: 25,
  },
  {
    name: "Page G",
    uv: 34,
    pv: 43,
    amt: 21,
  },
];

const AdsChart = () => {
  //   console.log(generateRandomData(getTimeIntervals()));
  return (
    <div className="chart-ads-content">
      <ResponsiveContainer width="100%" height={"100%"}>
        <AreaChart
          width={"100%"}
          height={"100%"}
          data={generateRandomData(getTimeIntervals())}
          syncId="anyId"
          margin={{
            top: 10,
            right: 0,
            left: 0,
            bottom: 0,
          }}
        >
          {/* <CartesianGrid strokeDasharray="3 3" /> */}
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <defs>
            <linearGradient id="colorUv" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#fece51" stopOpacity={0.8} />
              <stop offset="95%" stopColor="#fece51" stopOpacity={0} />
            </linearGradient>
          </defs>
          <Area
            type="monotone"
            dataKey="pv"
            stroke="#fece51"
            fill="url(#colorUv)"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
};

export default AdsChart;
