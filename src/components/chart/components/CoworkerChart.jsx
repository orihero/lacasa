import React from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
const data = [
  {
    name: "Coworker",
    AC: 40,
    LC: 24,
    SC: 30,
  },
  {
    name: "cwrk",
    AC: 30,
    LC: 13,
    SC: 20,
  },
  {
    name: "update cwrk",
    AC: 20,
    LC: 90,
    SC: 40,
  },
];
const CoworkerChart = () => {
  return (
    <div className="chart-coworker-chart">
      <ResponsiveContainer width="100%" height={"100%"}>
        <BarChart width={"100%"} height={350} data={data}>
          {/* <CartesianGrid strokeDasharray="3 3" /> */}
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Bar dataKey="AC" fill="#fece51" />
          <Bar dataKey="LC" fill="#82ca9d" />
          <Bar dataKey="SC" fill="#051d42" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default CoworkerChart;
