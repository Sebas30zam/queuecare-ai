import { BrandIcon } from "../icons";

export default function SurveyHeader() {
  return (
    <header className="border-b border-slate-200 bg-white shadow-sm">
      <div className="mx-auto flex min-h-16 w-full max-w-7xl items-center px-5 sm:px-8">
        <div className="flex items-center gap-2.5">
          <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-500 text-white shadow-sm">
            <BrandIcon />
          </span>

          <span className="text-lg font-extrabold tracking-tight text-blue-500">QueueCare AI</span>
        </div>
      </div>
    </header>
  );
}
