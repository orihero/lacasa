import { HandCoins, HousePlus } from "lucide-react";
function StatCard({ icon, label, value }) {
  return (
    <div className="chart-header-card flex flex-col gap-2 items-center text-center">
      <div className="mr-2 text-yellow-400">{icon}</div>
      <p className="text-2xl text-gray-600 text-muted-foreground">{label}</p>
      <p className="text-5xl text-yellow-400 font-semibold">{value}</p>
    </div>
  );
}

export default function HeaderCard() {
  const stats = [
    {
      icon: <HousePlus size={60} />,
      label: "Yaratilgan e'lonlar soni:",
      value: 14,
    },
    {
      icon: <HandCoins size={60} />,
      label: "Sotilgan e'lonlar soni:",
      value: 14,
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
