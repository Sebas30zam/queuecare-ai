import { FormEvent } from "react";

import { Link, useForm } from "@inertiajs/react";

import FormSection from "../../components/admin/FormSection";
import AppLayout from "../../layouts/AppLayout";

type RoleRecord = {
  id: number;
  name: string;
};

type UsersNewProps = {
  roles: RoleRecord[];
};

type UserFormData = {
  name: string;
  email: string;
  password: string;
  password_confirmation: string;
  role_id: string;
  active: boolean;
};

export default function UsersNew({ roles }: UsersNewProps) {
  const { data, setData, post, processing, errors, transform } = useForm<UserFormData>({
    name: "",
    email: "",
    password: "",
    password_confirmation: "",
    role_id: "",
    active: true,
  });

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    transform((formData) => ({
      user: formData,
    }));

    post("/users");
  }

  return (
    <AppLayout>
      <section className="mx-auto max-w-4xl space-y-6">
        <div>
          <Link
            href="/users"
            className="inline-flex items-center gap-2 text-sm font-semibold text-slate-500 transition hover:text-blue-600"
          >
            <span>←</span>
            Back to Staff Directory
          </Link>
        </div>

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 bg-gradient-to-r from-blue-50/80 via-white to-white px-7 py-7">
            <span className="rounded-full bg-blue-100 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
              Staff administration
            </span>

            <h1 className="mt-4 text-3xl font-bold tracking-tight text-slate-950">
              Create staff member
            </h1>

            <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
              Add a new account and configure the access this person will have inside QueueCare AI.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-7 p-7">
            <FormSection
              eyebrow="Account"
              title="Account information"
              description="Use the staff member's institutional information for their QueueCare AI account."
            >
              <div className="grid gap-5 md:grid-cols-2">
                <div>
                  <label htmlFor="name" className="mb-2 block text-sm font-bold text-slate-700">
                    Full name
                  </label>

                  <input
                    id="name"
                    type="text"
                    required
                    value={data.name}
                    onChange={(event) => setData("name", event.target.value)}
                    placeholder="e.g. Andrea Vargas"
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.name && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.name}</p>
                  )}
                </div>

                <div>
                  <label htmlFor="email" className="mb-2 block text-sm font-bold text-slate-700">
                    Institutional email
                  </label>

                  <input
                    id="email"
                    type="email"
                    required
                    value={data.email}
                    onChange={(event) => setData("email", event.target.value)}
                    placeholder="name@queuecare.com"
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.email && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.email}</p>
                  )}
                </div>
              </div>
            </FormSection>

            <FormSection
              eyebrow="Security"
              title="Initial password"
              description="The password is required when creating the account and can be changed later."
            >
              <div className="grid gap-5 md:grid-cols-2">
                <div>
                  <label htmlFor="password" className="mb-2 block text-sm font-bold text-slate-700">
                    Password
                  </label>

                  <input
                    id="password"
                    type="password"
                    required
                    value={data.password}
                    onChange={(event) => setData("password", event.target.value)}
                    placeholder="Enter a password"
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.password && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.password}</p>
                  )}
                </div>

                <div>
                  <label
                    htmlFor="password_confirmation"
                    className="mb-2 block text-sm font-bold text-slate-700"
                  >
                    Confirm password
                  </label>

                  <input
                    id="password_confirmation"
                    type="password"
                    required
                    value={data.password_confirmation}
                    onChange={(event) => setData("password_confirmation", event.target.value)}
                    placeholder="Repeat the password"
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.password_confirmation && (
                    <p className="mt-2 text-xs font-medium text-red-600">
                      {errors.password_confirmation}
                    </p>
                  )}
                </div>
              </div>
            </FormSection>

            <FormSection
              eyebrow="Access"
              title="Role and account status"
              description="The assigned role controls which QueueCare AI tools this account can access."
            >
              <div className="grid gap-5 md:grid-cols-2">
                <div>
                  <label htmlFor="role_id" className="mb-2 block text-sm font-bold text-slate-700">
                    Role
                  </label>

                  <select
                    id="role_id"
                    required
                    value={data.role_id}
                    onChange={(event) => setData("role_id", event.target.value)}
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  >
                    <option value="">Select a role</option>

                    {roles.map((role) => (
                      <option key={role.id} value={role.id}>
                        {role.name.charAt(0).toUpperCase() + role.name.slice(1)}
                      </option>
                    ))}
                  </select>

                  {errors.role_id && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.role_id}</p>
                  )}
                </div>

                <div>
                  <p className="mb-2 block text-sm font-bold text-slate-700">Account status</p>

                  <label className="flex cursor-pointer items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-4 py-3.5 transition hover:bg-white">
                    <div>
                      <p className="text-sm font-bold text-slate-800">Active account</p>

                      <p className="mt-0.5 text-xs text-slate-500">
                        Active users can sign in and access their assigned tools.
                      </p>
                    </div>

                    <input
                      type="checkbox"
                      checked={data.active}
                      onChange={(event) => setData("active", event.target.checked)}
                      className="h-5 w-5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                    />
                  </label>
                </div>
              </div>
            </FormSection>

            <div className="flex flex-col-reverse gap-3 border-t border-slate-100 pt-6 sm:flex-row sm:justify-end">
              <Link
                href="/users"
                className="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold text-slate-600 transition hover:bg-slate-50"
              >
                Cancel
              </Link>

              <button
                type="submit"
                disabled={processing}
                className="inline-flex items-center justify-center rounded-xl bg-blue-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {processing ? "Creating user..." : "Create user"}
              </button>
            </div>
          </form>
        </div>
      </section>
    </AppLayout>
  );
}
