type CommentFieldProps = {
  value: string;
  onChange: (comment: string) => void;
};

export default function CommentField({ value, onChange }: CommentFieldProps) {
  return (
    <label className="mt-8 block">
      <span className="text-sm font-semibold text-slate-800">
        Comentarios adicionales (opcional)
      </span>

      <textarea
        rows={4}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder="Escriba aquí sus observaciones o sugerencias..."
        className="mt-2 w-full resize-none rounded-xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-800 shadow-sm placeholder:text-slate-400 focus:border-blue-400 focus:bg-white focus:ring-blue-400"
      />
    </label>
  );
}
