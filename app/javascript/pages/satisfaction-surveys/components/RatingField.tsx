type RatingFieldProps = {
  value: number | null;
  onChange: (rating: number) => void;
};

const ratingOptions = [1, 2, 3, 4, 5];

export default function RatingField({ value, onChange }: RatingFieldProps) {
  return (
    <fieldset>
      <legend className="w-full text-center text-base font-semibold text-slate-800">
        ¿Cómo califica la atención recibida?
      </legend>

      <div className="mt-5 flex items-center justify-center gap-3 sm:gap-4">
        {ratingOptions.map((rating) => {
          const isSelected = value === rating;

          return (
            <button
              key={rating}
              type="button"
              aria-label={`Calificación ${rating} de 5`}
              aria-pressed={isSelected}
              onClick={() => onChange(rating)}
              className={[
                "flex h-12 w-12 items-center justify-center rounded-full border-2 text-base font-bold transition sm:h-13 sm:w-13",
                isSelected
                  ? "border-blue-500 bg-blue-50 text-blue-600 shadow-md shadow-blue-200/60"
                  : "border-slate-200 bg-white text-slate-600 hover:border-blue-300 hover:bg-blue-50/50",
              ].join(" ")}
            >
              {rating}
            </button>
          );
        })}
      </div>

      <div className="mt-4 flex items-center justify-between text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-slate-500">
        <span>Muy insatisfecho</span>
        <span>Muy satisfecho</span>
      </div>
    </fieldset>
  );
}
