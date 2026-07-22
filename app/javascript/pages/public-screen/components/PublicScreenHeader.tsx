import { formatTime } from "../utils";

type PublicScreenHeaderProps = {
  generatedAt: string;
};

export default function PublicScreenHeader({ generatedAt }: PublicScreenHeaderProps) {
  return (
    <header className="flex min-h-16 items-center justify-between border-b border-slate-800 bg-[#10182a] px-6 md:px-10">
      <div className="flex items-center gap-5">
        <div className="flex items-center gap-2 font-extrabold">
          <span className="h-6 w-6 rounded bg-white" />
          <span>QueueCare AI</span>
        </div>

        <span className="hidden h-6 w-px bg-slate-600 sm:block" />

        <span className="hidden text-sm font-semibold text-slate-300 sm:block">Waiting Room</span>
      </div>

      <time className="text-sm font-medium text-slate-400">{formatTime(generatedAt)}</time>
    </header>
  );
}
