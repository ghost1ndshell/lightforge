export type ApiErrorPayload = {
  error?: {
    code?: string;
    msg?: string;
  };
};

export async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`http://localhost:4000${path}`, {
    ...init,
    credentials: "include",
    headers: {
      accept: "application/json",
      ...(init?.headers ?? {}),
    },
  });

  const body = await res.json();

  if (!res.ok) {
    const msg = body?.error?.msg ?? "Request failed";

    throw new Error(msg);
  }

  return body as T;
}
