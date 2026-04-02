export type ApiErrorPayload = {
  error?: {
    code?: string;
    message?: string;
  };
};

export async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    ...init,
    credentials: "include",
    headers: {
      accept: "application/json",
      ...(init?.headers ?? {}),
    },
  });

  const body = await res.json();

  if (!res.ok) {
    const message = body?.error?.message ?? "Request failed";

    throw new Error(message);
  }

  return body as T;
}
