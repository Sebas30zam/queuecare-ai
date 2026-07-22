import { useForm } from "@inertiajs/react";
import type { FormEvent } from "react";

import { SendIcon } from "../icons";
import type { SurveyFormData } from "../types";
import CommentField from "./CommentField";
import RatingField from "./RatingField";

type SurveyFormProps = {
  serverErrors: string[];
};

export default function SurveyForm({ serverErrors }: SurveyFormProps) {
  const form = useForm<SurveyFormData>({
    rating: null,
    comment: "",
  });

  const canSubmit = form.data.rating !== null && !form.processing;

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    form.post(window.location.pathname, {
      preserveScroll: true,
    });
  };

  return (
    <form onSubmit={submit} className="mt-8 text-left">
      <RatingField value={form.data.rating} onChange={(rating) => form.setData("rating", rating)} />

      <CommentField
        value={form.data.comment}
        onChange={(comment) => form.setData("comment", comment)}
      />

      {serverErrors.length > 0 && (
        <div
          role="alert"
          className="mt-5 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
        >
          <p className="font-bold">No fue posible enviar la encuesta:</p>

          <ul className="mt-1 list-inside list-disc space-y-1">
            {serverErrors.map((error, index) => (
              <li key={`${error}-${index}`}>{error}</li>
            ))}
          </ul>
        </div>
      )}

      <button
        type="submit"
        disabled={!canSubmit}
        className="mt-6 inline-flex min-h-13 w-full items-center justify-center gap-3 rounded-xl bg-blue-400 px-6 py-3.5 text-base font-bold text-white shadow-lg shadow-blue-200/60 transition hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-50"
      >
        <span>{form.processing ? "Enviando..." : "Enviar encuesta"}</span>

        {!form.processing && <SendIcon />}
      </button>

      <p className="mt-4 text-center text-xs italic text-slate-400">
        Su respuesta será procesada de forma anónima para fines estadísticos.
      </p>
    </form>
  );
}
