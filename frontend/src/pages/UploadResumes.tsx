import { useState } from "react";
import { Navigation } from "@/components/Navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";
import { FileText, X, Code, EyeOff, Wand2, ChevronDown, ChevronUp } from "lucide-react";
import { FileUpload } from "@/components/FileUpload";
import { useUploadResume } from "@/hooks/useHRAgent";
import { ConditionalWebSocketLogs } from "@/components/ConditionalWebSocketLogs";
import { ResumeUploadInfo } from "@/components/BackendInfo";
import { hrAgentClient } from "@/api/hrAgentClient";

const PROFILES = ["backend","frontend","fullstack","sre","devops","data","ml","security","mobile","platform","analytics","ai","dx"];
const TEMPLATES = ["classic","sidebar","modern","clean","split"];

const UploadResumes = () => {
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [showBackendInfo, setShowBackendInfo] = useState(false);
  const { toast } = useToast();

  // Generate resume state
  const [showGenerate, setShowGenerate] = useState(false);
  const [genFirstName, setGenFirstName] = useState("");
  const [genLastName, setGenLastName] = useState("");
  const [genEmail, setGenEmail] = useState("");
  const [genProfile, setGenProfile] = useState("");
  const [genTemplate, setGenTemplate] = useState("");
  const [genInstructions, setGenInstructions] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);

  const handleGenerate = async () => {
    setIsGenerating(true);
    try {
      const result = await hrAgentClient.generateResume({
        first_name: genFirstName || undefined,
        last_name: genLastName || undefined,
        email: genEmail || undefined,
        profile: genProfile || undefined,
        template: genTemplate || undefined,
        instructions: genInstructions || undefined,
      });
      toast({
        title: "Resume generated",
        description: result.message,
      });
      // Reset form
      setGenFirstName(""); setGenLastName(""); setGenEmail("");
      setGenProfile(""); setGenTemplate(""); setGenInstructions("");
      setShowGenerate(false);
    } catch (e) {
      toast({ title: "Generation failed", description: String(e), variant: "destructive" });
    } finally {
      setIsGenerating(false);
    }
  };

  // Initialize the useUploadResume hook
  const { mutate: uploadResume, isPending: isUploadingResume } = useUploadResume();
  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
  };

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      toast({
        title: "No files selected",
        description: "Please select at least one resume to upload",
        variant: "destructive",
      });
      return;
    }

    setIsUploading(true);

    // Upload each file using the useUploadResume hook
    // The hook handles success/error toasts and query invalidation automatically
    for (const file of selectedFiles) {
      uploadResume(file);
    }

    // Reset state after uploads are initiated
    // The actual uploads will complete asynchronously
    setSelectedFiles([]);
    setIsUploading(false);
  };

  return (
    <div className="min-h-screen bg-background">
      <Navigation />
      
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-3xl mx-auto space-y-8">
          {/* Header */}
          <div className="flex items-center justify-between">
            <div className="space-y-3">
              <h1 className="text-4xl font-bold text-foreground">
                Upload Resumes
              </h1>
              <p className="text-muted-foreground text-lg">
                Add new candidate resumes to your database. Supported format: PDF
              </p>
            </div>

            {/* Backend Info Toggle */}
            <Button
              variant="outline"
              onClick={() => setShowBackendInfo(!showBackendInfo)}
              className="gap-2 border-slate-300 hover:bg-slate-100"
            >
              {showBackendInfo ? (
                <>
                  <EyeOff className="h-4 w-4" />
                  Hide Backend
                </>
              ) : (
                <>
                  <Code className="h-4 w-4" />
                  Show Backend
                </>
              )}
            </Button>
          </div>

          {/* Backend Information */}
          {showBackendInfo && (
            <div className="space-y-4">
              <div className="text-center">
                <h3 className="text-lg font-semibold text-slate-900 mb-4">
                  🔧 Backend Implementation Details
                </h3>
                <p className="text-sm text-slate-600 mb-4">
                  Click on the section below to see the backend code and technical details for resume processing.
                </p>
              </div>
              <ResumeUploadInfo />
            </div>
          )}

          {/* Generate Resume */}
          <div className="rounded-lg border border-border bg-card">
            <button
              className="w-full flex items-center justify-between px-4 py-3 text-left"
              onClick={() => setShowGenerate(v => !v)}
            >
              <span className="flex items-center gap-2 font-medium text-foreground">
                <Wand2 className="w-4 h-4" />
                Generate a random resume
              </span>
              {showGenerate ? <ChevronUp className="w-4 h-4 text-muted-foreground" /> : <ChevronDown className="w-4 h-4 text-muted-foreground" />}
            </button>

            {showGenerate && (
              <div className="px-4 pb-4 border-t border-border space-y-4 pt-4">
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1.5">
                    <Label htmlFor="gen-first">First name</Label>
                    <Input id="gen-first" placeholder="Random" value={genFirstName} onChange={e => setGenFirstName(e.target.value)} />
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="gen-last">Last name</Label>
                    <Input id="gen-last" placeholder="Random" value={genLastName} onChange={e => setGenLastName(e.target.value)} />
                  </div>
                </div>

                <div className="space-y-1.5">
                  <Label htmlFor="gen-email">Email</Label>
                  <Input id="gen-email" type="email" placeholder="Random" value={genEmail} onChange={e => setGenEmail(e.target.value)} />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1.5">
                    <Label htmlFor="gen-profile">Profile</Label>
                    <select
                      id="gen-profile"
                      value={genProfile}
                      onChange={e => setGenProfile(e.target.value)}
                      className="w-full h-9 rounded-md border border-input bg-background px-3 text-sm"
                    >
                      <option value="">Random</option>
                      {PROFILES.map(p => <option key={p} value={p}>{p}</option>)}
                    </select>
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="gen-template">Template</Label>
                    <select
                      id="gen-template"
                      value={genTemplate}
                      onChange={e => setGenTemplate(e.target.value)}
                      className="w-full h-9 rounded-md border border-input bg-background px-3 text-sm"
                    >
                      <option value="">Random</option>
                      {TEMPLATES.map(t => <option key={t} value={t}>{t}</option>)}
                    </select>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <Label htmlFor="gen-instructions">Extra instructions</Label>
                  <Textarea
                    id="gen-instructions"
                    placeholder="e.g. 10 years of experience, focus on Kubernetes and Go…"
                    rows={2}
                    value={genInstructions}
                    onChange={e => setGenInstructions(e.target.value)}
                  />
                </div>

                <Button onClick={handleGenerate} disabled={isGenerating} className="w-full">
                  <Wand2 className="w-4 h-4 mr-2" />
                  {isGenerating ? "Generating…" : "Generate & process"}
                </Button>
              </div>
            )}
          </div>

          {/* Upload Area */}
          <FileUpload onFileSelect={(file) => setSelectedFiles(prev => [...prev, file])} />

          {/* Selected Files List */}
          {selectedFiles.length > 0 && (
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-foreground">
                Selected Files ({selectedFiles.length})
              </h3>
              <div className="space-y-2">
                {selectedFiles.map((file, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-4 bg-muted/50 rounded-lg border border-border"
                  >
                    <div className="flex items-center gap-3">
                      <FileText className="w-5 h-5 text-primary" />
                      <div>
                        <p className="font-medium text-foreground">{file.name}</p>
                        <p className="text-sm text-muted-foreground">
                          {(file.size / (1024 * 1024)).toFixed(2)} MB
                        </p>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => removeFile(index)}
                    >
                      <X className="w-4 h-4" />
                    </Button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Upload Button */}
          <Button
            onClick={handleUpload}
            disabled={selectedFiles.length === 0 || isUploading || isUploadingResume}
            className="w-full h-12 text-base font-semibold"
          >
            {(isUploading || isUploadingResume) ? "Uploading..." : `Upload ${selectedFiles.length} Resume(s)`}
          </Button>
        </div>
      </div>
      <ConditionalWebSocketLogs/>
    </div>
  );
};

export default UploadResumes;
