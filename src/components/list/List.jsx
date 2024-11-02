import "./list.scss";
import Card from "../card/Card";

function List({ data = [] }) {
  if (data.length == 0) {
    return (
      <>
        <p style={{ color: "#888" }}>Not fount post</p>
      </>
    );
  }

  return (
    <div className="list">
      {data.map((item) => (
        <Card key={item.id} item={item} />
      ))}
    </div>
  );
}

export default List;
