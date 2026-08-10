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
      "Hello! I'm your QueueCare AI Operations Assistant. I can analyze wait times, service pressure, staffing patterns, no-show behavior, and historical operational activity.",
  },
];

const suggestedQuestions = [
  {
    title: "Wait time analysis",
    question: "Why is wait time high today?",
  },
  {
    title: "Service pressure",
    question: "Which service is under the most pressure?",
  },
  {
    title: "Staffing support",
    question: "Give me staffing recommendations.",
  },
];

function SparkIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-5 w-5"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      aria-hidden="true"
    >
      <path d="M12 3l1.4 4.1L17.5 8.5l-4.1 1.4L12 14l-1.4-4.1-4.1-1.4 4.1-1.4L12 3Z" />
      <path d="m18.5 14 .8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8.8-2.2Z" />
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

function ArrowIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-4 w-4"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      aria-hidden="true"
    >
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

export default function AiAssistantChat() {
  const [question, setQuestion] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isLoading]);

  async function submitQuestion(questionToSubmit: string) {
    const trimmedQuestion = questionToSubmit.trim();

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

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void submitQuestion(question);
  }

  return (
    <section
      aria-label="QueueCare AI assistant"
      className="overflow-hidden rounded-2xl border border-blue-100 bg-white shadow-sm"
    >
      <header className="shrink-0 border-b border-slate-100 px-6 py-5">
        <div className="flex items-start justify-between gap-4">
          <div className="flex min-w-0 items-start gap-3">
            <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-blue-600 text-white shadow-sm shadow-blue-200">
              <SparkIcon />
            </span>

            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="text-lg font-bold tracking-tight text-slate-950">
                  AI Operations Assistant
                </h2>

                <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-[9px] font-bold uppercase tracking-[0.12em] text-emerald-700">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                  Online
                </span>
              </div>

              <p className="mt-1.5 max-w-md text-xs leading-5 text-slate-500">
                Ask QueueCare AI about wait times, staffing, service load, or historical operational
                patterns.
              </p>
            </div>
          </div>

          <span className="shrink-0 rounded-full bg-blue-50 px-2.5 py-1 text-[9px] font-bold uppercase tracking-[0.12em] text-blue-700">
            Gemini
          </span>
        </div>
      </header>

      <div aria-live="polite" className="max-h-[360px] overflow-y-auto bg-slate-50/40 px-6 py-5">
        <div className="space-y-5">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}
            >
              {message.role === "assistant" ? (
                <div className="flex max-w-[92%] items-start gap-3">
                  <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-blue-600 text-white shadow-sm">
                    <SparkIcon />
                  </span>

                  <div>
                    <p className="mb-1.5 text-[9px] font-bold uppercase tracking-[0.12em] text-slate-400">
                      QueueCare AI
                    </p>

                    <div className="whitespace-pre-wrap rounded-2xl rounded-tl-md border border-slate-200 bg-white px-4 py-3.5 text-xs leading-6 text-slate-700 shadow-sm">
                      {message.content}
                    </div>
                  </div>
                </div>
              ) : (
                <div className="max-w-[82%]">
                  <p className="mb-1.5 text-right text-[9px] font-bold uppercase tracking-[0.12em] text-slate-400">
                    You
                  </p>

                  <div className="whitespace-pre-wrap rounded-2xl rounded-tr-md bg-blue-600 px-4 py-3.5 text-xs leading-6 text-white shadow-sm shadow-blue-100">
                    {message.content}
                  </div>
                </div>
              )}
            </div>
          ))}

          {messages.length === 1 && !isLoading && (
            <div className="pt-2">
              <p className="mb-3 text-[10px] font-bold uppercase tracking-[0.14em] text-slate-400">
                Try asking
              </p>

              <div className="grid gap-2 lg:grid-cols-3">
                {suggestedQuestions.map((suggestion) => (
                  <button
                    key={suggestion.question}
                    type="button"
                    onClick={() => void submitQuestion(suggestion.question)}
                    className="group flex w-full items-center justify-between gap-4 rounded-xl border border-slate-200 bg-white px-4 py-3 text-left transition hover:border-blue-200 hover:bg-blue-50/50 hover:shadow-sm"
                  >
                    <div>
                      <p className="text-xs font-bold text-slate-800">{suggestion.title}</p>

                      <p className="mt-1 text-[10px] text-slate-500">{suggestion.question}</p>
                    </div>

                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-slate-50 text-slate-400 transition group-hover:bg-blue-100 group-hover:text-blue-700">
                      <ArrowIcon />
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {isLoading && (
            <div className="flex items-start gap-3">
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-blue-600 text-white">
                <SparkIcon />
              </span>

              <div>
                <p className="mb-1.5 text-[9px] font-bold uppercase tracking-[0.12em] text-slate-400">
                  QueueCare AI
                </p>

                <div className="rounded-2xl rounded-tl-md border border-slate-200 bg-white px-4 py-3 shadow-sm">
                  <div className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500 [animation-delay:-0.3s]" />
                    <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500 [animation-delay:-0.15s]" />
                    <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500" />
                  </div>
                </div>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>
      </div>

      <form
        onSubmit={handleSubmit}
        className="shrink-0 border-t border-slate-100 bg-white px-5 py-4"
      >
        <div className="rounded-2xl border border-slate-200 bg-white p-2 shadow-sm transition focus-within:border-blue-300 focus-within:ring-4 focus-within:ring-blue-50">
          <label htmlFor="ai-assistant-question" className="sr-only">
            Ask QueueCare AI
          </label>

          <textarea
            id="ai-assistant-question"
            value={question}
            onChange={(event) => setQuestion(event.target.value)}
            disabled={isLoading}
            maxLength={1000}
            rows={3}
            placeholder="Ask QueueCare AI about your operation..."
            className="max-h-32 min-h-[72px] w-full resize-none border-0 bg-transparent px-3 py-2 text-xs leading-5 text-slate-900 outline-none placeholder:text-slate-400 focus:ring-0 disabled:cursor-not-allowed disabled:opacity-60"
          />

          <div className="flex items-center justify-between gap-3 border-t border-slate-100 px-2 pt-2">
            <div>
              <p className="text-[9px] font-semibold text-slate-400">
                Based on QueueCare AI operational data
              </p>
            </div>

            <button
              type="submit"
              aria-label="Send question"
              disabled={!question.trim() || isLoading}
              className="flex h-9 items-center gap-2 rounded-xl bg-blue-600 px-3.5 text-xs font-bold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-slate-300"
            >
              Send
              <SendIcon />
            </button>
          </div>
        </div>
      </form>
    </section>
  );
}
