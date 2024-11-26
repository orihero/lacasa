import { HandCoins, HousePlus } from "lucide-react";
function StatCard({ icon, label, value }) {
  return (
    <div className="chart-header-card flex flex-col gap-2 items-center text-center">
      <div className="mr-2 text-yellow-400">{icon}</div>
      <p className="text-2xl text-gray-600 text-muted-foreground">{label}</p>
      <p className="text-5xl text-black font-bold font-semibold">{value}</p>
    </div>
  );
}

export default function HeaderCard({ data }) {
  const stats = [
    {
      icon: <HousePlus size={60} />,
      label: "Yaratilgan e'lonlar soni:",
      value: data.newCount,
    },
    {
      icon: <HandCoins size={60} color="#82ca9d" />,
      label: "Sotilgan e'lonlar soni:",
      value: data.soldCount,
    },
  ];

  return (
    <div className="flex gap-2">
      {stats.map((stat) => (
        <StatCard
          key={stat.label}
          icon={stat.icon}
          label={stat.label}
          value={stat.value}
        />
      ))}
    </div>
  );
}
