import { useEffect, useMemo, useState } from "react";
import { Search, Users } from "lucide-react";
import { apiClient } from "../../lib/apiClient";
import AgentCard from "../components/AgentCard";

// Agent directory (mockup #/u-agents) — every realtor on the platform, with
// a client-side name filter.
function AgentsDirectoryPage() {
  const [agents, setAgents] = useState(null);
  const [query, setQuery] = useState("");

  useEffect(() => {
    apiClient.agents
      .list()
      .then((list) => setAgents([...list].sort((a, b) => b.adsCount - a.adsCount)))
      .catch((error) => {
        console.error(error);
        setAgents([]);
      });
  }, []);

  const visible = useMemo(() => {
    if (!agents) return null;
    const q = query.trim().toLowerCase();
    return q ? agents.filter((a) => a.fullName?.toLowerCase().includes(q)) : agents;
  }, [agents, query]);

  return (
    <div className="wrap pad">
      <div className="rowhead">
        <div>
          <h2 className="h2">Agents</h2>
          <p className="sub">
            {agents === null
              ? "Loading…"
              : `${agents.length} verified realtor${agents.length === 1 ? "" : "s"} working across Tashkent`}
          </p>
        </div>
        <div className="field" style={{ width: 240, marginBottom: 0 }}>
          <Search size={14} style={{ flex: "none" }} />
          <input
            style={{ border: 0, background: "transparent", outline: "none", width: "100%" }}
            placeholder="Search agents"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
      </div>
      <div className="grid grid--3">
        {visible === null
          ? Array.from({ length: 3 }, (_, i) => <div key={i} className="skeleton" style={{ minHeight: 180 }} />)
          : visible.map((agent) => <AgentCard key={agent.id} agent={agent} />)}
      </div>
      {visible !== null && visible.length === 0 && (
        <div className="empty">
          <Users size={38} />
          <b>No agents found</b>
          <p>Try a different name.</p>
        </div>
      )}
    </div>
  );
}

export default AgentsDirectoryPage;
