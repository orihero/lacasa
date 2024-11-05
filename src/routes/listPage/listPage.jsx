import { Triangle } from "react-loader-spinner";
import Card from "../../components/card/Card";
import { useListStore } from "../../lib/adsListStore";
import "./listPage.scss";
import HorizontalCard from "../../components/h-card/HCard";

function ListPage() {
  const { list, isLoading } = useListStore();

  if (isLoading) {
    return (
      <div className="loading">
        <Triangle
          visible={true}
          height="80"
          width="80"
          color="#4fa94d"
          ariaLabel="triangle-loading"
          wrapperStyle={{}}
          wrapperClass=""
        />
      </div>
    );
  }

  return (
    <div className="listPage">
      <div className="listContainer">
        <div className="wrapper">
          {list.map((item) => (
            <HorizontalCard key={item.id} data={item} />
          ))}
        </div>
      </div>
    </div>
  );
}

export default ListPage;
