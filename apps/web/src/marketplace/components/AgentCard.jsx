import { useNavigate } from "react-router-dom";
import { UserRound } from "lucide-react";

// Directory card for one agent (mockup .agent). `dealsClosedCount` only
// exists on the detail endpoint, so the second stat renders when present.
function AgentCard({ agent }) {
  const navigate = useNavigate();

  return (
    <button className="agentcard" onClick={() => navigate(`/agent/${agent.id}`)}>
      <div
        className="agentcard__av"
        style={agent.avatar ? { backgroundImage: `url(${agent.avatar})` } : undefined}
      >
        {!agent.avatar && <UserRound size={28} />}
      </div>
      <div className="agentcard__n">{agent.fullName}</div>
      <div className="agentcard__r">Agent · Tashkent</div>
      <div className="agentcard__s">
        <div>
          <b className="num">{agent.adsCount}</b>
          <span>Listings</span>
        </div>
        {agent.dealsClosedCount != null && (
          <div>
            <b className="num">{agent.dealsClosedCount}</b>
            <span>Closed</span>
          </div>
        )}
      </div>
    </button>
  );
}

export default AgentCard;
