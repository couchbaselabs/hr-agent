import { useState, useEffect } from "react";
import { NavLink } from "@/components/NavLink";
import { Search, Upload, Sparkles, Activity, FileText, CalendarDays, Loader2 } from "lucide-react";
import { hrAgentClient, AIProviderSettings } from "@/api/hrAgentClient";

function AIProviderToggle() {
  const [settings, setSettings] = useState<AIProviderSettings | null>(null);
  const [switching, setSwitching] = useState(false);

  useEffect(() => {
    hrAgentClient.getAIProvider()
      .then(setSettings)
      .catch(() => setSettings({ provider: "openai" }));
  }, []);

  const toggle = async () => {
    if (!settings || switching) return;
    const next = settings.provider === "openai" ? "gemini" : "openai";
    setSwitching(true);
    try {
      const updated = await hrAgentClient.setAIProvider(next);
      setSettings(updated);
    } catch {
      // revert on failure — keep current settings
    } finally {
      setSwitching(false);
    }
  };

  if (!settings) return null;

  const isGemini = settings.provider === "gemini";

  return (
    <button
      onClick={toggle}
      disabled={switching}
      title={`Active: ${settings.provider}${settings.model ? ` (${settings.model})` : ""}. Click to switch.`}
      className="flex items-center gap-1.5 px-3 py-1.5 rounded-md border border-border text-xs font-medium transition-colors hover:bg-accent disabled:opacity-50"
    >
      {switching ? (
        <Loader2 className="w-3.5 h-3.5 animate-spin" />
      ) : isGemini ? (
        <span className="text-blue-400 font-bold">✦</span>
      ) : (
        <span className="text-green-400 font-bold">⬡</span>
      )}
      <span className={isGemini ? "text-blue-400" : "text-green-400"}>
        {isGemini ? "Gemini" : "OpenAI"}
      </span>
    </button>
  );
}

export const Navigation = () => {
  return (
    <nav className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          <div className="flex items-center gap-2">
            <h2 className="text-xl font-bold text-foreground">Agentic HR Sourcing</h2>
          </div>

          <div className="flex items-center gap-2">
            <NavLink
              to="/"
              className="flex items-center gap-2 px-4 py-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
              activeClassName="bg-accent text-foreground font-medium"
            >
              <Search className="w-4 h-4" />
              <span>Search Candidates</span>
            </NavLink>

            <NavLink
              to="/agent-match"
              className="flex items-center gap-2 px-4 py-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
              activeClassName="bg-accent text-foreground font-medium"
            >
              <Sparkles className="w-4 h-4" />
              <span>AI Agent Match</span>
            </NavLink>

            <NavLink
              to="/upload-resumes"
              className="flex items-center gap-2 px-4 py-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
              activeClassName="bg-accent text-foreground font-medium"
            >
              <Upload className="w-4 h-4" />
              <span>Upload Resumes</span>
            </NavLink>

            <NavLink
              to="/traces"
              className="flex items-center gap-2 px-4 py-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
              activeClassName="bg-accent text-foreground font-medium"
            >
              <Activity className="w-4 h-4" />
              <span>Traces</span>
            </NavLink>

            <NavLink
              to="/applications"
              className="flex items-center gap-2 px-4 py-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
              activeClassName="bg-accent text-foreground font-medium"
            >
              <FileText className="w-4 h-4" />
              <span>Applications</span>
            </NavLink>

            <NavLink
              to="/meetings"
              className="flex items-center gap-2 px-4 py-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
              activeClassName="bg-accent text-foreground font-medium"
            >
              <CalendarDays className="w-4 h-4" />
              <span>Meetings</span>
            </NavLink>

            <div className="ml-2 pl-2 border-l border-border">
              <AIProviderToggle />
            </div>
          </div>
        </div>
      </div>
    </nav>
  );
};
