import { useEffect, useRef, useState } from "react";
import type { FormEvent } from "react";

type ChatMessage = {
  id: number;
  role: "user" | "assistant";
  content: string;
};

type AssistantResponse = {
  answer?: string;
  error?: string;
};

const initialMessages: ChatMessage[] = [
  {
    id: 1,
    role: "assistant",
    content:
      "Hello! I can answer questions about your current QueueCare AI operation. What would you like to know?",
  },
];

function ChatIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-6 w-6"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      aria-hidden="true"
    >
      <path d="M21 12a8 8 0 0 1-8 8H7l-4 3v-6a8 8 0 1 1 18-5Z" />
      <path d="M8 12h.01M12 12h.01M16 12h.01" />
    </svg>
  );
}

function SendIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-5 w-5"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      aria-hidden="true"
    >
      <path d="m22 2-7 20-4-9-9-4Z" />
      <path d="M22 2 11 13" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-5 w-5"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      aria-hidden="true"
    >
      <path d="m6 6 12 12M18 6 6 18" />
    </svg>
  );
}

export default function AiAssistantChat() {
  const [isOpen, setIsOpen] = useState(false);
  const [question, setQuestion] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!isOpen) return;

    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [isOpen, messages, isLoading]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const trimmedQuestion = question.trim();

    if (!trimmedQuestion || isLoading) return;

    const userMessage: ChatMessage = {
      id: Date.now(),
      role: "user",
      content: trimmedQuestion,
    };

    setMessages((currentMessages) => [...currentMessages, userMessage]);
    setQuestion("");
    setIsLoading(true);

    try {
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content;

      const headers: Record<string, string> = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };

      if (csrfToken) {
        headers["X-CSRF-Token"] = csrfToken;
      }

      const response = await fetch("/dashboard/ai-assistant", {
        method: "POST",
        credentials: "same-origin",
        headers,
        body: JSON.stringify({ question: trimmedQuestion }),
      });

      const data = (await response.json()) as AssistantResponse;

      if (!response.ok) {
        throw new Error(data.error ?? "The AI assistant could not answer.");
      }

      const answer = data.answer;

      if (!answer) {
        throw new Error("The AI assistant returned an empty response.");
      }

      setMessages((currentMessages) => [
        ...currentMessages,
        {
          id: Date.now() + 1,
          role: "assistant",
          content: answer,
        },
      ]);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : "The AI assistant is temporarily unavailable.";

      setMessages((currentMessages) => [
        ...currentMessages,
        {
          id: Date.now() + 1,
          role: "assistant",
          content: errorMessage,
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="fixed bottom-6 right-6 z-50">
      {isOpen && (
        <section
          aria-label="QueueCare AI assistant"
          className="mb-4 flex h-[min(600px,calc(100vh-120px))] w-[calc(100vw-48px)] max-w-[390px] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20"
        >
          <header className="flex items-center justify-between bg-gradient-to-r from-blue-600 to-indigo-700 px-5 py-4 text-white">
            <div className="flex items-center gap-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/15">
                <ChatIcon />
              </span>

              <div>
                <h2 className="text-sm font-bold">QueueCare AI Assistant</h2>

                <p className="mt-0.5 text-[11px] text-blue-100">
                  Operational insights powered by Gemini
                </p>
              </div>
            </div>

            <button
              type="button"
              aria-label="Close assistant"
              onClick={() => setIsOpen(false)}
              className="flex h-9 w-9 items-center justify-center rounded-lg text-blue-100 transition hover:bg-white/15 hover:text-white"
            >
              <CloseIcon />
            </button>
          </header>

          <div
            aria-live="polite"
            className="flex-1 space-y-4 overflow-y-auto bg-slate-50 px-4 py-5"
          >
            {messages.map((message) => (
              <div
                key={message.id}
                className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[85%] whitespace-pre-wrap rounded-2xl px-4 py-3 text-xs leading-5 ${
                    message.role === "user"
                      ? "rounded-br-md bg-blue-600 text-white"
                      : "rounded-bl-md border border-slate-200 bg-white text-slate-700 shadow-sm"
                  }`}
                >
                  {message.content}
                </div>
              </div>
            ))}

            {isLoading && (
              <div className="flex justify-start">
                <div className="rounded-2xl rounded-bl-md border border-slate-200 bg-white px-4 py-3 shadow-sm">
                  <div className="flex items-center gap-1.5">
                    <span className="h-2 w-2 animate-bounce rounded-full bg-blue-500 [animation-delay:-0.3s]" />
                    <span className="h-2 w-2 animate-bounce rounded-full bg-blue-500 [animation-delay:-0.15s]" />
                    <span className="h-2 w-2 animate-bounce rounded-full bg-blue-500" />
                  </div>
                </div>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          <form onSubmit={handleSubmit} className="border-t border-slate-200 bg-white p-4">
            <div className="flex items-center gap-2">
              <label htmlFor="ai-assistant-question" className="sr-only">
                Ask QueueCare AI
              </label>

              <input
                id="ai-assistant-question"
                type="text"
                value={question}
                onChange={(event) => setQuestion(event.target.value)}
                disabled={isLoading}
                maxLength={1000}
                autoComplete="off"
                placeholder="Ask about your operation..."
                className="min-w-0 flex-1 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-2 focus:ring-blue-100 disabled:cursor-not-allowed disabled:opacity-60"
              />

              <button
                type="submit"
                aria-label="Send question"
                disabled={!question.trim() || isLoading}
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-blue-600 text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-slate-300"
              >
                <SendIcon />
              </button>
            </div>

            <p className="mt-2 text-center text-[10px] text-slate-400">
              Answers are based on QueueCare AI operational data.
            </p>
          </form>
        </section>
      )}

      <button
        type="button"
        aria-label={isOpen ? "Close AI assistant" : "Open AI assistant"}
        aria-expanded={isOpen}
        onClick={() => setIsOpen((currentValue) => !currentValue)}
        className="ml-auto flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-br from-blue-600 to-indigo-700 text-white shadow-lg shadow-blue-500/30 transition hover:scale-105 hover:shadow-xl focus:outline-none focus:ring-4 focus:ring-blue-200"
      >
        {isOpen ? <CloseIcon /> : <ChatIcon />}
      </button>
    </div>
  );
}
