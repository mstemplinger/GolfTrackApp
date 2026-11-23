"use client";

import { removeOperator } from "./actions";

/** Löschen mit Rückfrage – lässt sich nicht rückgängig machen. */
export function DeleteOperatorButton({ id, name }: { id: string; name: string }) {
  return (
    <form
      action={removeOperator}
      onSubmit={(e) => {
        if (!confirm(`Konto „${name}“ endgültig löschen? Das lässt sich nicht rückgängig machen.`)) e.preventDefault();
      }}
    >
      <input type="hidden" name="id" value={id} />
      <button
        type="submit"
        className="rounded-lg border border-[#e07a63]/50 px-4 py-2 text-sm text-[#e07a63] transition-colors hover:bg-[#e07a63]/10"
      >
        Endgültig löschen
      </button>
    </form>
  );
}
