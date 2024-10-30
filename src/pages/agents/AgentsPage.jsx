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
      {list.map((agent) => {
        return <AgentCard agent={agent} />;
      })}
      <div className="item-agent">
        <div>
          <span>
            Name: <b>Jonibek</b>
          </span>
          <span>
            Phone: <b>+998 99 999 99 99</b>
          </span>
          <span>
            E-mail: <b>realter@gmail.com</b>
          </span>
          <span>
            Telegram:{" "}
            <a href="https://t.me/@uy_bozor_joy_savdo" target="_blank">
              @uy_bozor_joy_savdo
            </a>
          </span>
          <span>
            Instagram:{" "}
            <a href="https://t.me/@uy_bozor_joy_savdo" target="_blank">
              @uy_bozor_joy_savdo
            </a>
          </span>
          <span>
            Web site:{" "}
            <a
              href="https://ismoilabdujalilov6.wixsite.com/-site-1"
              target="_blank"
            >
              ismoilabdujalilov6.wixsite.com
            </a>
          </span>
          <span>
            Address: <b>Toshkent, Yangi hayot, 8-mavze</b>
          </span>
          <span>
            Review:{" "}
            <span className="stars">
              {[1, 2, 3, 4, 5].map((item) => {
                if (item <= 4) {
                  return <img className="star-icon" src="/icons/star.svg" />;
                } else {
                  return <img className="star-icon" src="/icons/star1.svg" />;
                }
              })}{" "}
            </span>
            <b>4.5</b>
          </span>
          <span>
            Ads: <b>12</b>
          </span>
        </div>
        <div className="right-agent">
          <span>
            <img src={"/avatar.jpg"} alt="" />
          </span>
          <span className="agent-btns">
            <button>Contact</button>
            <button>View Listings</button>
          </span>
        </div>
      </div>
    </div>
  );
};

export default AgentsPage;
