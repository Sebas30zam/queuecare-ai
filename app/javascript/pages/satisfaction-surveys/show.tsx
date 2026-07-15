import { Head, useForm } from "@inertiajs/react";
import type { FormEvent } from "react";

import GuestLayout from "../../layouts/GuestLayout";

type QueueServiceRecord = {
  id: number;
  name: string;
  code: string;
};

type ServiceWindowRecord = {
  id: number;
  name: string;
  code: string;
};

type SurveyTicket = {
  ticket_number: string;
  status: string;
  queue_service: QueueServiceRecord;
  service_window: ServiceWindowRecord | null;
};

type SatisfactionSurveyProps = {
  ticket: SurveyTicket;
  submitted: boolean;
  errors: string[];
};

type SurveyFormData = {
  rating: number | null;
  comment: string;
};

const ratingOptions = [1, 2, 3, 4, 5];

function BrandIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-6 w-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth="2"
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 12h3l2-7 4 14 3-10 2 3h4" />
    </svg>
  );
}

function SendIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-5 w-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth="1.8"
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M4 4l16 8-16 8 3-8-3-8Zm3 8h13" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-9 w-9"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth="2"
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="m5 12 4 4L19 6" />
    </svg>
  );
}

export default function SatisfactionSurvey({
  ticket,
  submitted,
  errors: serverErrors,
}: SatisfactionSurveyProps) {
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
    <GuestLayout>
      <Head title="Satisfaction Survey" />

      <div className="flex min-h-screen flex-col bg-slate-50">
        <header className="border-b border-slate-200 bg-white shadow-sm">
          <div className="mx-auto flex min-h-16 w-full max-w-7xl items-center px-5 sm:px-8">
            <div className="flex items-center gap-2.5">
              <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-500 text-white shadow-sm">
                <BrandIcon />
              </span>

              <span className="text-lg font-extrabold tracking-tight text-blue-500">
                QueueCare AI
              </span>
            </div>
          </div>
        </header>

        <main className="flex flex-1 items-center justify-center bg-gradient-to-br from-sky-50 via-white to-slate-50 px-4 py-10 sm:px-6">
          <section className="w-full max-w-xl rounded-2xl border border-slate-100 bg-white px-6 py-8 shadow-xl shadow-slate-300/40 sm:px-10 sm:py-10">
            <div className="text-center">
              <div className="inline-flex items-center gap-2 rounded-full border border-blue-100 bg-blue-50 px-4 py-2 shadow-sm">
                <span className="text-[0.65rem] font-extrabold uppercase tracking-[0.16em] text-blue-500">
                  Ticket
                </span>

                <span className="font-extrabold text-slate-800">{ticket.ticket_number}</span>
              </div>

              {submitted ? (
                <div className="py-8">
                  <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
                    <CheckIcon />
                  </div>

                  <h1 className="mt-6 text-3xl font-black tracking-tight text-slate-900">
                    Gracias por su opinión
                  </h1>

                  <p className="mx-auto mt-3 max-w-sm text-sm leading-6 text-slate-500">
                    Su encuesta fue enviada correctamente. Su respuesta nos ayudará a mejorar la
                    atención.
                  </p>

                  <div className="mt-7 rounded-xl border border-slate-200 bg-slate-50 px-5 py-4">
                    <p className="font-bold text-slate-800">{ticket.queue_service.name}</p>

                    <p className="mt-1 text-sm text-slate-500">
                      {ticket.service_window?.name ?? "Ventanilla no asignada"}
                    </p>
                  </div>
                </div>
              ) : (
                <>
                  <h1 className="mt-6 text-3xl font-black tracking-tight text-slate-900">
                    Encuesta de Satisfacción
                  </h1>

                  <p className="mt-2 text-sm leading-6 text-slate-500">
                    Valoramos su tiempo. Por favor, califique su experiencia hoy.
                  </p>

                  <div className="mt-4 flex flex-wrap items-center justify-center gap-x-2 text-sm text-slate-500">
                    <span>{ticket.queue_service.name}</span>
                    <span aria-hidden="true">·</span>
                    <span>{ticket.service_window?.name ?? "Ventanilla no asignada"}</span>
                  </div>

                  <form onSubmit={submit} className="mt-8 text-left">
                    <fieldset>
                      <legend className="w-full text-center text-base font-semibold text-slate-800">
                        ¿Cómo califica la atención recibida?
                      </legend>

                      <div className="mt-5 flex items-center justify-center gap-3 sm:gap-4">
                        {ratingOptions.map((rating) => {
                          const isSelected = form.data.rating === rating;

                          return (
                            <button
                              key={rating}
                              type="button"
                              aria-label={`Calificación ${rating} de 5`}
                              aria-pressed={isSelected}
                              onClick={() => form.setData("rating", rating)}
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

                    <label className="mt-8 block">
                      <span className="text-sm font-semibold text-slate-800">
                        Comentarios adicionales (opcional)
                      </span>

                      <textarea
                        rows={4}
                        value={form.data.comment}
                        onChange={(event) => form.setData("comment", event.target.value)}
                        placeholder="Escriba aquí sus observaciones o sugerencias..."
                        className="mt-2 w-full resize-none rounded-xl border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-800 shadow-sm placeholder:text-slate-400 focus:border-blue-400 focus:bg-white focus:ring-blue-400"
                      />
                    </label>

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
                </>
              )}
            </div>
          </section>
        </main>

        <footer className="border-t border-slate-200 bg-white">
          <div className="mx-auto flex min-h-14 w-full max-w-7xl flex-col items-center justify-between gap-2 px-5 py-4 text-xs text-slate-500 sm:flex-row sm:px-8">
            <span>© 2026 QueueCare AI — Universidad de Gestión Operativa</span>

            <div className="flex items-center gap-6">
              <span>Soporte Técnico</span>
              <span>Privacidad</span>
            </div>
          </div>
        </footer>
      </div>
    </GuestLayout>
  );
}
