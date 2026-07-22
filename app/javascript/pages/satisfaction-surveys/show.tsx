import { Head } from "@inertiajs/react";

import GuestLayout from "../../layouts/GuestLayout";
import SurveyFooter from "./components/SurveyFooter";
import SurveyForm from "./components/SurveyForm";
import SurveyHeader from "./components/SurveyHeader";
import { CheckIcon } from "./icons";
import type { SatisfactionSurveyProps } from "./types";

export default function SatisfactionSurvey({
  ticket,
  submitted,
  errors: serverErrors,
}: SatisfactionSurveyProps) {
  return (
    <GuestLayout>
      <Head title="Satisfaction Survey" />

      <div className="flex min-h-screen flex-col bg-slate-50">
        <SurveyHeader />

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

                  <SurveyForm serverErrors={serverErrors} />
                </>
              )}
            </div>
          </section>
        </main>

        <SurveyFooter />
      </div>
    </GuestLayout>
  );
}
