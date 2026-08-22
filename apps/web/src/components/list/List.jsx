import "./list.scss";
import Card from "../card/Card";
import { Triangle } from "react-loader-spinner";

function List({ data = [], isLoading = false }) {
  if (data.length == 0) {
    return (
      <>
        <p style={{ color: "#888" }}>Not fount post</p>
      </>
    );
  }

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
    <div className="list">
      {data.map((item) => (
        <Card key={item.id} item={item} />
      ))}
    </div>
  );
}

export default List;
