export default function SurveyFooter() {
  return (
    <footer className="border-t border-slate-200 bg-white">
      <div className="mx-auto flex min-h-14 w-full max-w-7xl flex-col items-center justify-between gap-2 px-5 py-4 text-xs text-slate-500 sm:flex-row sm:px-8">
        <span>© 2026 QueueCare AI — Universidad de Gestión Operativa</span>

        <div className="flex items-center gap-6">
          <span>Soporte Técnico</span>
          <span>Privacidad</span>
        </div>
      </div>
    </footer>
  );
}
