import React from "react";
import {
  Area,
  AreaChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  generateRandomData,
  getTimeIntervals,
} from "../../../hooks/formatDate";

const AdsChart = ({ selectedTime }) => {
  return (
    <div className="chart-ads-content">
      <ResponsiveContainer width="100%" height={"100%"}>
        <AreaChart
          width={"100%"}
          height={"100%"}
          data={generateRandomData(getTimeIntervals(selectedTime))}
          // data={[]}
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
            <linearGradient id="colorPv" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#82ca9d" stopOpacity={0.8} />
              <stop offset="95%" stopColor="#82ca9d" stopOpacity={0} />
            </linearGradient>
          </defs>
          <Area
            type="monotone"
            dataKey="create"
            stroke="#fece51"
            fill="url(#colorUv)"
          />
          <Area
            type="monotone"
            dataKey="sold"
            stroke="#82ca9d"
            fill="url(#colorPv)"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
};

export default AdsChart;
