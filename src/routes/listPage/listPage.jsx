import Card from "../../components/card/Card";
import { listData } from "../../lib/dummydata";
import "./listPage.scss";

function ListPage() {
  const data = listData;

  return (
    <div className="listPage">
      <div className="listContainer">
        <div className="wrapper">
          {data.map((item) => (
            <Card key={item.id} item={item} />
          ))}
        </div>
      </div>
    </div>
  );
}

export default ListPage;
