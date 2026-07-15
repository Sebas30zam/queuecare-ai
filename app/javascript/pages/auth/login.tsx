import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";

import GuestLayout from "../../layouts/GuestLayout";

type LoginForm = {
  email: string;
  password: string;
};

type LoginProps = {
  errors?: {
    email?: string;
  };
};

const demoCredentials = [
  { role: "Admin", email: "admin@queuecare.com" },
  { role: "Reception", email: "receptionist@queuecare.com" },
  { role: "Agent", email: "agent@queuecare.com" },
  { role: "Supervisor", email: "supervisor@queuecare.com" },
];

export default function Login({ errors }: LoginProps) {
  const { data, setData, post, processing } = useForm<LoginForm>({
    email: "",
    password: "",
  });

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    post("/login");
  }

  return (
    <GuestLayout>
      <div className="flex min-h-screen flex-col items-center bg-gradient-to-br from-sky-50 via-white to-emerald-50 px-8 py-8">
        <div className="mb-6 text-center">
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-blue-500 text-xl font-bold text-white">
            Q
          </div>

          <h1 className="text-3xl font-bold text-blue-500">QueueCare AI</h1>

          <h2 className="mt-4 text-xl font-bold text-slate-950">Intelligent queue management</h2>

          <p className="mt-2 text-sm text-slate-500">
            Operational attention and analytics for universities.
          </p>
        </div>

        <form
          onSubmit={handleSubmit}
          className="w-full max-w-md rounded-xl bg-white shadow-2xl shadow-slate-300/60"
        >
          <div className="border-b border-slate-100 px-6 py-6">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h3 className="text-xl font-bold text-slate-950">Sign in</h3>

                <p className="mt-1 text-xs text-slate-500">
                  Enter your institutional credentials to access the panel.
                </p>
              </div>

              <div className="rounded-full bg-blue-50 px-2 py-1 text-xs font-semibold text-blue-500">
                Secure
              </div>
            </div>

            {errors?.email && (
              <div className="mt-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-600">
                {errors.email}
              </div>
            )}

            <div className="mt-5">
              <label className="text-xs font-semibold text-slate-700">Email</label>

              <input
                type="email"
                value={data.email}
                onChange={(event) => setData("email", event.target.value)}
                placeholder="user@university.edu"
                className="mt-2 w-full rounded-lg border border-slate-200 px-3 py-3 text-sm outline-none transition placeholder:text-slate-400 focus:border-blue-500"
              />
            </div>

            <div className="mt-4">
              <div className="flex items-center justify-between">
                <label className="text-xs font-semibold text-slate-700">Password</label>

                <span className="text-xs font-medium text-blue-500">Forgot your password?</span>
              </div>

              <input
                type="password"
                value={data.password}
                onChange={(event) => setData("password", event.target.value)}
                placeholder="••••••••"
                className="mt-2 w-full rounded-lg border border-slate-200 px-3 py-3 text-sm outline-none transition placeholder:text-slate-400 focus:border-blue-500"
              />
            </div>

            <button
              type="submit"
              disabled={processing}
              className="mt-5 w-full rounded-lg bg-blue-500 px-4 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-500/25 transition hover:bg-blue-600 disabled:cursor-not-allowed disabled:opacity-70"
            >
              {processing ? "Signing in..." : "Enter the system →"}
            </button>
          </div>

          <p className="px-5 py-4 text-center text-xs text-slate-500">
            By signing in, you accept QueueCare AI usage and privacy policies.
          </p>
        </form>

        <div className="mt-8 w-full max-w-sm rounded-xl border border-slate-200 bg-white px-5 py-5 shadow-sm">
          <p className="mb-3 text-center text-xs font-bold uppercase tracking-wide text-slate-500">
            Demo credentials
          </p>

          <div className="space-y-2">
            {demoCredentials.map((credential) => (
              <div
                key={credential.email}
                className="flex items-center justify-between gap-3 text-xs"
              >
                <span className="font-semibold text-slate-600">{credential.role}:</span>

                <span className="rounded bg-slate-50 px-2 py-1 text-slate-500">
                  {credential.email}
                </span>
              </div>
            ))}
          </div>

          <p className="mt-4 text-center text-xs text-slate-400">
            Default password: <strong>password123</strong>
          </p>
        </div>

        <footer className="mt-auto pt-8 text-center text-xs text-slate-400">
          © 2026 QueueCare AI — University Operations System
        </footer>
      </div>
    </GuestLayout>
  );
}
