type ConfirmDialogProps = {
  open: boolean;
  title: string;
  description: string;
  confirmLabel: string;
  processing?: boolean;
  onCancel: () => void;
  onConfirm: () => void;
};

export default function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel,
  processing = false,
  onCancel,
  onConfirm,
}: ConfirmDialogProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/40 p-4 backdrop-blur-sm">
      <div className="w-full max-w-md overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl">
        <div className="p-6">
          <div className="flex h-11 w-11 items-center justify-center rounded-full bg-red-50 text-lg font-bold text-red-600">
            !
          </div>

          <h2 className="mt-4 text-xl font-bold text-slate-950">{title}</h2>

          <p className="mt-2 text-sm leading-6 text-slate-600">{description}</p>
        </div>

        <div className="flex justify-end gap-3 border-t border-slate-100 bg-slate-50 px-6 py-4">
          <button
            type="button"
            onClick={onCancel}
            disabled={processing}
            className="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:opacity-50"
          >
            Cancel
          </button>

          <button
            type="button"
            onClick={onConfirm}
            disabled={processing}
            className="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {processing ? "Deleting..." : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
