import "./list.scss";
import Card from "../card/Card";

function List({ data = [] }) {
  return (
    <div className="list">
      {data.map((item) => (
        <Card key={item.id} item={item} />
      ))}
    </div>
  );
}

export default List;
