import React, { useEffect } from "react";
import "./agents.scss";
import { useAgentsStore } from "../../lib/agentsStore";
import AgentCard from "../../components/agent/AgentCard";
import { Triangle } from "react-loader-spinner";

const AgentsPage = () => {
  const { fetchAgentList, isLoading, list } = useAgentsStore();
  useEffect(() => {
    fetchAgentList();
  }, []);

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
    <div className="list-agent">
      {list?.map((agent) => {
        return <AgentCard agent={agent} />;
      })}
    </div>
  );
};

export default AgentsPage;
