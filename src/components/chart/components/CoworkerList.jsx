import React from "react";

const CoworkerList = ({ data }) => {
  const products = [
    { name: "Marble Cake", sales: 1647, stock: 62 },
    { name: "Fat Rascal", sales: 1240, stock: 48 },
    { name: "Chocolate Cake", sales: 1080, stock: 57 },
    { name: "Goose Breast", sales: 1014, stock: 41 },
    { name: "Petit Gâteau", sales: 985, stock: 23 },
    { name: "Salzburger Nockerl", sales: 962, stock: 34 },
    { name: "Salzburger Nockerl", sales: 962, stock: 34 },
    { name: "Salzburger Nockerl", sales: 962, stock: 34 },
    { name: "Salzburger Nockerl", sales: 962, stock: 34 },
    { name: "Salzburger Nockerl", sales: 962, stock: 34 },
    { name: "Salzburger Nockerl", sales: 962, stock: 34 },
  ];

  return (
    <div className="w-full p-3 bg-white chart-coworker-content">
      {/* <h2 className="text-2xl font-semibold text-gray-900 mb-6">Coworkers</h2> */}
      <div className="w-full">
        <div className="grid grid-cols-2 gap-2 mb-4">
          <div className="text-sm font-medium text-gray-900">Coworkers</div>
          <div className="grid grid-cols-3 gap-1">
            <div className="text-sm font-medium text-gray-900">Ads count</div>
            <div className="text-sm font-medium text-gray-900">Lead count</div>
            <div className="text-sm font-medium text-gray-900">Sale count</div>
          </div>
        </div>
        <div className="overflow-scroll chart-coworker-list">
          {data.map((coworker, index) => (
            <div
              key={coworker.id}
              className="grid grid-cols-2 items-center gap-2 py-1 border-b border-gray-100 last:border-0"
            >
              <div className="text-sm flex items-center gap-2 text-gray-500">
                <img
                  className="chart-coworker-img"
                  src={coworker.avatar ?? "/avatar.jpg"}
                  alt=""
                />
                <span>{coworker.fullName}</span>
              </div>
              <div className="grid grid-cols-3 gap-1">
                <div className="text-sm text-gray-500">
                  {products[index].sales}
                </div>
                <div className="text-sm text-gray-500">
                  {products[index].sales}
                </div>
                <div className="text-sm text-gray-500">
                  {products[index].stock}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default CoworkerList;
